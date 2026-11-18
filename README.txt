# BOARD GAME LOUNGE — Supabase Edition

## ไฟล์ในโฟลเดอร์
- `index.html` — โครงสร้างเว็บไซต์
- `style.css` — ตกแต่งเว็บไซต์
- `app.js` — การทำงานและเชื่อม Supabase
- `supabase-config.js` — Project URL และ Publishable Key
- `supabase-setup.sql` — คำสั่งสร้างตารางและสิทธิ์ RLS

## ขั้นตอนติดตั้ง Supabase
1. เข้าโปรเจกต์ Supabase เดิมของ Board Game Online
2. เปิดเมนู SQL Editor
3. กด New query
4. เปิดไฟล์ `supabase-setup.sql` ด้วย Notepad หรือ VS Code
5. คัดลอก SQL ทั้งหมดไปวางใน SQL Editor แล้วกด Run
6. ต้องเห็นข้อความ Success ก่อนทดสอบเว็บไซต์

## วิธีเปิดเว็บไซต์
1. แตกไฟล์ ZIP
2. เปิดโฟลเดอร์นี้ด้วย VS Code
3. เปิดด้วย Live Server หรือโฮสต์บน GitHub Pages
4. ตรวจสอบว่า `supabase-config.js` มี Project URL และ Publishable Key ที่ถูกต้อง

## สมัครและตั้ง Admin
1. เปิดเว็บไซต์แล้วสมัครสมาชิกด้วยอีเมลของตัวเอง
2. ไป Supabase > Table Editor > profiles
3. หาแถวที่มีอีเมล/บัญชีของตัวเอง (ตาราง profiles ใช้ id; เทียบกับ Authentication > Users)
4. เปลี่ยนค่า `role` ของแถวนั้นจาก `member` เป็น `admin`
5. ออกจากระบบแล้วเข้าสู่ระบบใหม่ จะเห็นสิทธิ์ผู้ดูแล

## หมายเหตุ
- ใช้ Publishable Key หรือ anon key เท่านั้น ห้ามใช้ `service_role` หรือ Secret key ในไฟล์หน้าเว็บ
- ถ้าเปิด Email confirmation อยู่ ต้องกดยืนยันอีเมลก่อนเข้าสู่ระบบ
- คลังเกมและสมาชิกตัวอย่างในหน้าค้นหาเพื่อนเป็นข้อมูลสาธิต; สมาชิกที่สมัครจริงจะแสดงจาก profiles
- เวอร์ชันนี้ใช้ Supabase Auth, Database และ Row Level Security (RLS)
- การเข้าร่วมห้องเก็บเป็นสมาชิกห้องจริงใน `room_members`; ควรเพิ่มระบบแชต/นัดหมายภายหลังหากต้องการ
