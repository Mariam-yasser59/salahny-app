import nodemailer from 'nodemailer';
import dns from 'dns/promises';
import { Resend } from 'resend';

let resendClient;

const normalizedSmtpPass = () => process.env.SMTP_PASS?.replace(/\s/g, '') || '';

const cleanEmailValue = (value = '') => {
  const text = String(value || '').trim();
  const markdownMailto = text.match(/^\[([^\]]+)\]\(mailto:([^)]+)\)$/i);
  if (markdownMailto) return markdownMailto[2].trim();
  const markdownEmail = text.match(/^\[([^\]]+)\]\([^)]+\)$/);
  if (markdownEmail) return markdownEmail[1].trim();
  return text.replace(/^mailto:/i, '').trim();
};

const configuredFrom = () =>
  cleanEmailValue(
    process.env.EMAIL_FROM ||
      process.env.RESEND_FROM ||
      process.env.SENDGRID_FROM ||
      process.env.SMTP_USER ||
      '',
  );

const configuredReplyTo = () =>
  cleanEmailValue(process.env.EMAIL_REPLY_TO || process.env.SMTP_USER || '');

const smtpReady = () => {
  const pass = normalizedSmtpPass();
  return Boolean(
    process.env.SMTP_HOST?.trim() &&
      process.env.SMTP_USER?.trim() &&
      pass &&
      pass !== 'GMAIL_APP_PASSWORD_HERE',
  );
};

const cachedTransporters = new Map();

const parseEmailAddress = (value = '') => {
  const text = cleanEmailValue(value || configuredFrom());
  const match = text.match(/^(.*?)<([^>]+)>$/);
  if (match) {
    return {
      name: match[1].trim().replace(/^"|"$/g, '') || undefined,
      email: match[2].trim(),
    };
  }
  return { email: text.replace(/^"|"$/g, '').trim() };
};

const apiProvider = () => {
  const requested = process.env.EMAIL_PROVIDER?.trim().toLowerCase();
  if (requested) return requested;
  if (process.env.SENDGRID_API_KEY) return 'sendgrid';
  if (process.env.RESEND_API_KEY) return 'resend';
  return 'smtp';
};

const apiEmailReady = () =>
  (apiProvider() === 'sendgrid' && Boolean(process.env.SENDGRID_API_KEY)) ||
  (apiProvider() === 'resend' && Boolean(process.env.RESEND_API_KEY));

const smtpPort = () => Number(process.env.SMTP_PORT || 587);
const smtpSecure = (port = smtpPort()) =>
  String(process.env.SMTP_SECURE || '').toLowerCase() === 'true' ||
  String(port) === '465';

const smtpConfigForLogs = (override = {}) => ({
  host: process.env.SMTP_HOST || '',
  port: override.port ?? smtpPort(),
  secure: override.secure ?? smtpSecure(override.port ?? smtpPort()),
  user: process.env.SMTP_USER || '',
  from: configuredFrom(),
  passConfigured: Boolean(process.env.SMTP_PASS),
});

const resolveSmtpEndpoint = async () => {
  const configuredHost = process.env.SMTP_HOST;
  if (String(process.env.SMTP_FORCE_IPV4 || 'true').toLowerCase() !== 'true') {
    return { host: configuredHost, servername: configuredHost };
  }
  const result = await dns.lookup(configuredHost, { family: 4 });
  return { host: result.address, servername: configuredHost };
};

const getTransporter = async ({ port = smtpPort(), secure = smtpSecure(port) } = {}) => {
  if (!smtpReady()) {
    console.warn('[email] SMTP is not configured', smtpConfigForLogs());
    return null;
  }
  const cacheKey = `${port}:${secure}`;
  if (cachedTransporters.has(cacheKey)) return cachedTransporters.get(cacheKey);

  const smtpEndpoint = await resolveSmtpEndpoint();
  const transporter = nodemailer.createTransport({
    host: smtpEndpoint.host,
    port,
    family: 4,
    secure,
    connectionTimeout: Number(process.env.SMTP_CONNECTION_TIMEOUT_MS || 7000),
    greetingTimeout: Number(process.env.SMTP_GREETING_TIMEOUT_MS || 7000),
    socketTimeout: Number(process.env.SMTP_SOCKET_TIMEOUT_MS || 9000),
    auth: {
      user: process.env.SMTP_USER,
      pass: normalizedSmtpPass(),
    },
    tls: {
      servername: smtpEndpoint.servername,
    },
  });
  cachedTransporters.set(cacheKey, transporter);
  return transporter;
};

const shouldRetryOnAlternatePort = (error, port) =>
  port === 587 &&
  String(process.env.SMTP_FALLBACK_PORT || '465') !== '587' &&
  /timeout|enetunreach|econnrefused|etimedout/i.test(
    `${error.message || ''} ${error.code || ''}`,
  );

const sendWithConfig = async ({ to, subject, text, html, port = smtpPort(), secure = smtpSecure(port) }) => {
  const transporter = await getTransporter({ port, secure });
  if (!transporter) return { sent: false, reason: 'smtp_not_configured' };
  const info = await transporter.sendMail({
    from: configuredFrom(),
    to,
    subject,
    text,
    html,
  });
  return { sent: true, messageId: info.messageId, info, port, secure };
};

const sendWithSendGrid = async ({ to, subject, text, html }) => {
  const from = parseEmailAddress(process.env.SENDGRID_FROM || configuredFrom());
  const response = await fetch('https://api.sendgrid.com/v3/mail/send', {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${process.env.SENDGRID_API_KEY}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      personalizations: [{ to: [{ email: to }] }],
      from,
      reply_to: parseEmailAddress(configuredReplyTo()),
      subject,
      content: [
        ...(text ? [{ type: 'text/plain', value: text }] : []),
        ...(html ? [{ type: 'text/html', value: html }] : []),
      ],
    }),
  });
  if (!response.ok) {
    throw new Error(`SendGrid ${response.status}: ${await response.text()}`);
  }
  return {
    sent: true,
    messageId: response.headers.get('x-message-id') || undefined,
    provider: 'sendgrid',
  };
};

const sendWithResend = async ({ to, subject, text, html }) => {
  if (!resendClient) {
    resendClient = new Resend(process.env.RESEND_API_KEY);
  }
  const { data, error } = await resendClient.emails.send({
    from: configuredFrom(),
    to,
    subject,
    text,
    html,
    replyTo: configuredReplyTo() || undefined,
  });
  if (error) {
    throw new Error(`Resend ${error.statusCode || 'error'}: ${error.message || 'send_failed'}`);
  }
  return { sent: true, messageId: data?.id, provider: 'resend' };
};

const sendWithApiProvider = async ({ to, subject, text, html }) => {
  const provider = apiProvider();
  if (provider === 'sendgrid') return sendWithSendGrid({ to, subject, text, html });
  if (provider === 'resend') return sendWithResend({ to, subject, text, html });
  return { sent: false, reason: 'api_email_not_configured' };
};

export const sendEmail = async ({ to, subject, text, html }) => {
  if (!to) return { sent: false, reason: 'missing_recipient' };
  if (apiEmailReady()) {
    try {
      const result = await sendWithApiProvider({ to, subject, text, html });
      if (result.sent) {
        console.info('[email] Email sent successfully', {
          provider: result.provider,
          messageId: result.messageId,
        });
        return { sent: true, messageId: result.messageId };
      }
    } catch (error) {
      console.error('[email] Email failed', {
        provider: apiProvider(),
        message: error.message,
      });
      return {
        sent: false,
        reason: 'send_failed',
        error: error.message,
      };
    }
  }

  const primaryPort = smtpPort();
  try {
    const result = await sendWithConfig({ to, subject, text, html, port: primaryPort });
    if (!result.sent) return result;
    const { info } = result;
    console.info('[email] Email sent successfully', {
      messageId: info.messageId,
      accepted: info.accepted,
      rejected: info.rejected,
      port: result.port,
    });
    return { sent: true, messageId: info.messageId };
  } catch (error) {
    if (shouldRetryOnAlternatePort(error, primaryPort)) {
      const fallbackPort = Number(process.env.SMTP_FALLBACK_PORT || 465);
      try {
        console.warn('[email] retrying SMTP on fallback port', {
          primaryPort,
          fallbackPort,
          error: error.message,
        });
        const result = await sendWithConfig({
          to,
          subject,
          text,
          html,
          port: fallbackPort,
          secure: smtpSecure(fallbackPort),
        });
        if (!result.sent) return result;
        console.info('[email] sent on fallback port', {
          to,
          subject,
          messageId: result.info.messageId,
          port: fallbackPort,
        });
        return { sent: true, messageId: result.info.messageId };
      } catch (fallbackError) {
        console.error('[email] fallback SMTP failed', {
          to,
          subject,
          primaryError: error.message,
          fallbackError: fallbackError.message,
          fallbackCode: fallbackError.code,
          config: smtpConfigForLogs({ port: fallbackPort, secure: smtpSecure(fallbackPort) }),
        });
        return {
          sent: false,
          reason: 'send_failed',
          error: fallbackError.message,
          code: fallbackError.code,
        };
      }
    }
    console.error('[email] failed to send message', {
      message: error.message,
      code: error.code,
      command: error.command,
      response: error.response,
      config: smtpConfigForLogs({ port: primaryPort, secure: smtpSecure(primaryPort) }),
    });
    return {
      sent: false,
      reason: 'send_failed',
      error: error.message,
      code: error.code,
    };
  }
};

export const getEmailProviderStatus = () => ({
  provider: apiProvider(),
  configured: apiEmailReady() || smtpReady(),
  from: configuredFrom(),
  replyToConfigured: Boolean(configuredReplyTo()),
  resendConfigured: Boolean(process.env.RESEND_API_KEY),
  smtpConfigured: smtpReady(),
});

export const sendAccountStatusEmail = async ({ user, status, notes = '' }) => {
  if (!user?.email) return { sent: false, reason: 'missing_email' };

  const approved = status === 'active' || status === 'approved';
  const isWorkshop = user.role === 'workshop';
  const subject = approved
    ? isWorkshop
      ? 'Your Salahny workshop account has been approved'
      : 'Your Salahny account has been approved'
    : isWorkshop
      ? 'Your Salahny workshop account was rejected'
      : 'Your Salahny account was rejected';
  const body = approved
    ? isWorkshop
      ? `Hello ${user.name},\n\nYour workshop account has been approved. You can now log in and receive service requests.\n\nThank you,\nSalahny Team`
      : `Hello ${user.name},\n\nYour Salahny account has been approved. You can now log in and use the app.\n\nThank you,\nSalahny Team`
    : `Hello ${user.name},\n\nYour ${isWorkshop ? 'workshop account' : 'Salahny account'} verification was rejected.${
        notes ? `\n\nAdmin notes: ${notes}` : ''
      }\n\nPlease review your submitted information or contact support.\n\nThank you,\nSalahny Team`;

  return sendEmail({
    to: user.email,
    subject,
    text: body,
    html: body
      .split('\n')
      .map((line) => `<p>${line || '&nbsp;'}</p>`)
      .join(''),
  });
};

