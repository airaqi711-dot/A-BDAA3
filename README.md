# نظام تثبيت الطلبات

1. أنشئ مشروعاً في https://supabase.com.
2. افتح SQL Editor وشغّل محتوى `setup.sql`.
3. في Authentication > Users أنشئ مستخدم الإدارة ببريد وكلمة مرور.
4. نفّذ في SQL Editor: `insert into public.admins(user_id) values ('UUID');` واستبدل UUID بمعرّف المستخدم المنشأ.
5. من Project Settings > API Keys خذ مفتاح publishable/anon، ومن إعدادات المشروع خذ Project URL، وضعهما في أعلى سكربت `index.html`. **لا تضع مفتاح service_role أو secret في HTML.**
6. ارفع `index.html` على استضافة HTTPS ثابتة مثل Netlify أو Cloudflare Pages، أو شغّله محلياً بخادم HTTP للتجربة.

مهم: نموذج أولي مناسب للبداية. للإطلاق العام يوصى بإضافة CAPTCHA وrate limiting على مستوى الخادم، وسياسة خصوصية ونسخ احتياطية، وتنظيف الصور المرفوعة غير المرتبطة بطلبات. صلاحيات الطلبات مبنية على RLS، وصور الطلبات في bucket خاص.
