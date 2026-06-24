import nodemailer from 'nodemailer';

const transporter = nodemailer.createTransport({
  host: process.env.EMAIL_HOST,
  port: Number(process.env.EMAIL_PORT || 587),
  secure: false,
  auth: {
    user: process.env.EMAIL_USER,
    pass: process.env.EMAIL_PASS,
  },
});

export const sendAccountApprovedEmail = async (email, name) => {
  await transporter.sendMail({
    from: `"Salahny" <${process.env.EMAIL_FROM}>`,
    to: email,
    subject: 'Your Salahny account has been approved',
    html: `
      <div style="font-family: Arial, sans-serif;">
        <h2>Account Approved ✅</h2>

        <p>Hello ${name || 'User'},</p>

        <p>Your Salahny account has been approved successfully.</p>

        <p>You can now login to the application.</p>

        <br/>

        <p><strong>Salahny Team</strong></p>
      </div>
    `,
  });
};