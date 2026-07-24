import { Resend } from 'resend';
import dotenv from 'dotenv';
dotenv.config();

const RESEND_API_KEY = process.env.RESEND_API_KEY || 're_9oteDiAi_Ggn5oinWHw7NutjK5VM8h963';
const SENDER_EMAIL = process.env.SENDER_EMAIL || 'Sirvya <noreply@devunivers.com>';

export const resend = new Resend(RESEND_API_KEY);

const SIRVYA_LOGO_URL = 'https://raw.githubusercontent.com/anas-gn/Fitlek/main/assets/branding/logo_dark.png';

export async function sendOTPEmail({ to, otp, type = 'signup' }) {
  const isSignUp = type === 'signup';
  const title = isSignUp ? 'Verify Your Email' : 'Reset Your Password';
  const subtitle = isSignUp
    ? 'Use the verification code below to complete your Sirvya registration.'
    : 'Use the code below to reset your Sirvya account password.';

  const htmlContent = `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <style>
        body { font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; background-color: #0b1d28; margin: 0; padding: 40px 20px; color: #ffffff; }
        .card { max-width: 500px; margin: 0 auto; background-color: #122836; border-radius: 16px; border: 1px solid #1e3a4c; padding: 40px 30px; text-align: center; box-shadow: 0 10px 30px rgba(0,0,0,0.3); }
        .logo-container { margin-bottom: 24px; text-align: center; }
        .logo-img { height: 75px; width: auto; max-width: 240px; border: 0; display: inline-block; object-fit: contain; }
        h1 { font-size: 22px; font-weight: 800; color: #ffffff; margin-bottom: 12px; }
        p { font-size: 14px; color: #a0b3c6; line-height: 1.6; margin-bottom: 28px; }
        .otp-box { background: linear-gradient(135deg, #e5c158 0%, #d4a938 100%); color: #0b1d28; font-size: 36px; font-weight: 900; letter-spacing: 8px; padding: 18px 24px; border-radius: 12px; display: inline-block; margin-bottom: 28px; }
        .footer { font-size: 12px; color: #5a738e; margin-top: 32px; border-top: 1px solid #1e3a4c; padding-top: 20px; }
      </style>
    </head>
    <body>
      <div class="card">
        <div class="logo-container">
          <img class="logo-img" src="${SIRVYA_LOGO_URL}" alt="SIRVYA" />
        </div>
        <h1>${title}</h1>
        <p>${subtitle}</p>
        <div class="otp-box">${otp}</div>
        <p style="margin-bottom: 0;">This code expires in <strong>10 minutes</strong>. If you did not request this, please ignore this email.</p>
        <div class="footer">
          &copy; ${new Date().getFullYear()} DevUnivers (Morocco) - Sirvya Platform
        </div>
      </div>
    </body>
    </html>
  `;

  try {
    const data = await resend.emails.send({
      from: SENDER_EMAIL,
      to: [to],
      subject: isSignUp ? `Your Sirvya Verification Code: ${otp}` : `Reset Password Code: ${otp}`,
      html: htmlContent,
    });
    console.log(`✉️ Resend OTP email sent to ${to}:`, data);
    return { success: true, data };
  } catch (error) {
    console.error(`❌ Failed to send OTP email to ${to}:`, error.message);
    throw error;
  }
}
