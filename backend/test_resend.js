import { Resend } from 'resend';
import dotenv from 'dotenv';
dotenv.config();

const resend = new Resend(process.env.RESEND_API_KEY);

async function testResend() {
  try {
    console.log('Sending test email...');
    const data = await resend.emails.send({
      from: process.env.SENDER_EMAIL || 'onboarding@resend.dev',
      to: 'test@example.com', // Change this to something valid if needed, or see what error it throws
      subject: 'Test Email',
      html: '<p>This is a test.</p>',
    });
    console.log('Success:', data);
  } catch (error) {
    console.error('Error:', error);
  }
}

testResend();
