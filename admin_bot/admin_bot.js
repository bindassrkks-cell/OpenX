const { Telegraf, Markup } = require("telegraf");
const { createClient } = require("@supabase/supabase-js");

const BOT_TOKEN = "7663258345:AAFWanmBg6FD_DQTz2q9tkvHX-8M9vAWkUA";
const bot = new Telegraf(BOT_TOKEN);

const supabase = createClient(
  process.env.SUPABASE_URL || "https://xyz.supabase.co",
  process.env.SUPABASE_KEY || "dummy-key"
);

bot.start((ctx) => {
  ctx.reply(
    `👋 Welcome Boss! Store Control Bot Active.\n\nAapka Chat ID hai: \`${ctx.chat.id}\``,
    { parse_mode: "Markdown" }
  );
});

bot.action(/approve_(.+)/, async (ctx) => {
  const orderId = ctx.match[1];
  await ctx.answerCbQuery("Payment Approved!");
  await ctx.reply(`✅ Order \`${orderId}\` approved. Shiprocket se dispatch karein.`);
});

bot.launch().then(() => console.log("🤖 Bot is running..."));
