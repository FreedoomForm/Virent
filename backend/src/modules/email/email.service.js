/**
 * email.service.js — Email notification system
 *
 * Per Backend Design System §20: notifications via multiple channels
 * Uses nodemailer (configured via env) or console fallback for dev.
 *
 * Templates: welcome, trip_ended, low_balance, password_reset, promo
 */
const path = require('path');

const TEMPLATES = {
  welcome: {
    subject: 'Добро пожаловать в SparkRentals!',
    body: (data) => `Здравствуйте, ${data.firstName}!\n\nДобро пожаловать в SparkRentals — шеринг электросамокатов.\n\nВаш аккаунт создан. Начните первую поездку прямо сейчас!\n\nС уважением,\nКоманда SparkRentals`,
  },
  trip_ended: {
    subject: 'Поездка завершена',
    body: (data) => `Поездка завершена!\n\nДлительность: ${data.durationMin} мин\nСтоимость: ${data.cost} сум\nЗона завершения: ${data.endZone}\nОстаток на балансе: ${data.balance} сум\n\nСпасибо за использование SparkRentals!`,
  },
  low_balance: {
    subject: 'Низкий баланс',
    body: (data) => `Ваш баланс: ${data.balance} сум.\n\nПополните баланс, чтобы продолжить пользоваться самокатами.\n\nПерейдите в приложение → Кошелёк → Пополнить`,
  },
  password_reset: {
    subject: 'Сброс пароля',
    body: (data) => `Ваш код для сброса пароля: ${data.code}\n\nКод действителен 10 минут.\n\nЕсли вы не запрашивали сброс пароля, проигнорируйте это письмо.`,
  },
  promo: {
    subject: 'Новый промокод для вас!',
    body: (data) => `Вам доступен промокод: ${data.code}\n\n${data.description}\n\nПримените его в приложении: Кошелёк → Промокод`,
  },
};

const emailService = {
  /**
   * Send email by template name
   */
  send: async function(toEmail, templateName, data = {}) {
    const template = TEMPLATES[templateName];
    if (!template) {
      console.error(`[email] Unknown template: ${templateName}`);
      return { ok: false, error: 'Unknown template' };
    }
    if (!toEmail) {
      return { ok: false, error: 'No email address' };
    }

    const subject = template.subject;
    const text = template.body(data);

    // Try to use nodemailer if configured
    const smtpHost = process.env.SMTP_HOST;
    if (smtpHost) {
      try {
        const nodemailer = require('nodemailer');
        const transporter = nodemailer.createTransport({
          host: smtpHost,
          port: parseInt(process.env.SMTP_PORT || '587'),
          secure: process.env.SMTP_SECURE === 'true',
          auth: {
            user: process.env.SMTP_USER,
            pass: process.env.SMTP_PASS,
          },
        });
        await transporter.sendMail({
          from: process.env.SMTP_FROM || 'noreply@sparkrentals.uz',
          to: toEmail,
          subject,
          text,
        });
        console.log(`[email] Sent "${templateName}" to ${toEmail}`);
        return { ok: true, provider: 'smtp' };
      } catch (e) {
        console.error(`[email] SMTP failed: ${e.message}, falling back to console`);
      }
    }

    // Dev fallback: log to console
    console.log(`\n[EMAIL DEV MODE]`);
    console.log(`  To: ${toEmail}`);
    console.log(`  Subject: ${subject}`);
    console.log(`  Body: ${text}`);
    console.log('');
    return { ok: true, provider: 'console' };
  },

  /**
   * Send welcome email after registration
   */
  sendWelcome: function(email, firstName) {
    return this.send(email, 'welcome', { firstName });
  },

  /**
   * Send trip ended email
   */
  sendTripEnded: function(email, data) {
    return this.send(email, 'trip_ended', data);
  },

  /**
   * Send low balance warning
   */
  sendLowBalance: function(email, balance) {
    return this.send(email, 'low_balance', { balance });
  },

  /**
   * Send password reset code
   */
  sendPasswordReset: function(email, code) {
    return this.send(email, 'password_reset', { code });
  },
};

module.exports = emailService;
