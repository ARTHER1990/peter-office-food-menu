/**
 * 🍱 Peter Food Menu - Smart Nutrition Calculator Engine
 * คำนวณแคลอรี่ สารอาหารหลัก และเวลาวิ่ง/เดินเบิร์นตามหลักโภชนาการไทย (ยึดหลักข้าวสวย 1 ทัพพี)
 */

const fs = require('fs');
const path = require('path');

const RICE_1_SERVING = { calories: 80, carbs: 18, protein: 1.5, fat: 0.2 }; // ข้าวสวย 1 ทัพพีมาตรฐาน
const BURN_RATE_RUNNING = 10.0; // kcal ต่อนาที (วิ่ง 8-9 km/h)
const BURN_RATE_WALKING = 5.8;  // kcal ต่อนาที (เดินเร็ว 5-6 km/h)

// ฐานข้อมูลสารอาหารอ้างอิงของอาหารไทยยอดนิยม
const DISH_DATABASE = {
  "น้ำพริกอ่อง": { cal: 150, p: 12, c: 8, f: 8, tip: "ไฟเบอร์สูงจากผักสดและมะเขือเทศ" },
  "ไข่ต้ม": { cal: 75, p: 6.5, c: 0.5, f: 5.0, tip: "โปรตีนคุณภาพสูง ย่อยง่าย" },
  "ต้มจืดเต้าหู้": { cal: 90, p: 7, c: 4, f: 4, tip: "โปรตีนจากเต้าหู้ขาว ซดคล่องคอ" },
  "สุกี้หมู": { cal: 360, p: 24, c: 38, f: 11, tip: "ผักเยอะ ไฟเบอร์แน่น ระวังน้ำจิ้มโซเดียม" },
  "ก๋วยจั๊บ": { cal: 480, p: 22, c: 54, f: 18, tip: "พริกไทยร้อนแรงช่วยขับลม ลดซดน้ำซุปเพื่อเลี่ยงโซเดียม" },
  "หมูมะนาว": { cal: 220, p: 22, c: 6, f: 11, tip: "รสแซ่บโปรตีนแน่น ไขมันต่ำ กระตุ้นการเผาผลาญ" },
  "ต้มจืดไข่น้ำ": { cal: 120, p: 8, c: 3, f: 8, tip: "ไข่น้ำนุ่มฟู ย่อยง่าย" },
  "ยำวุ้นเส้น": { cal: 160, p: 10, c: 26, f: 2, tip: "แคลอรี่ต่ำ รสแซ่บตัดเลี่ยนได้ดี" },
  "แกงแพนงหมู": { cal: 240, p: 14, c: 6, f: 18, tip: "หอมกะทิและพริกแกงสมุนไพร" },
  "ข้าวยำไก่แซ่บ": { cal: 420, p: 24, c: 38, f: 18, tip: "โปรตีนจากไก่เน้นๆ รสจัดจ้าน" },
  "ผัดซีอิ๊วหมู": { cal: 480, p: 20, c: 52, f: 20, tip: "คาร์บและพลังงานเต็มเปี่ยม ผักคะน้าแคลเซียมสูง" },
  "ก๋วยเตี๋ยวไก่ฉีก": { cal: 380, p: 26, c: 48, f: 8, tip: "ไขมันต่ำ ย่อยง่าย ไม่ง่วงตอนบ่าย" },
  "ไข่ลูกเขย": { cal: 220, p: 13, c: 20, f: 10, tip: "รสเปรี้ยวหวานกลมกล่อม มีโปรตีนจากไข่" },
  "ต้มจับฉ่าย": { cal: 180, p: 12, c: 10, f: 9, tip: "ผักเปื่อยวิตามินและกากใยอาหารสูงมาก" },
  "ปิ้งงบ": { cal: 140, p: 16, c: 4, f: 6, tip: "หอมสมุนไพรใบตอง โปรตีนดีจากเนื้อปลา" },
  "ไข่พะโล้": { cal: 260, p: 18, c: 14, f: 14, tip: "หอมเครื่องเทศโป๊ยกั๊กอบเชย" },
  "ขนมจีนน้ำยาไก่": { cal: 380, p: 20, c: 44, f: 12, tip: "ทานแกล้มผักสดเคียงเยอะๆ เพิ่มกากใย" },
  "ก๋วยเตี๋ยวหมูตุ๋น": { cal: 460, p: 25, c: 52, f: 15, tip: "หมูตุ๋นเปื่อยนุ่ม น้ำซุปสมุนไพรหอมกรุ่น" },
  "ผัดผักกาดขาวหมูกรอบ": { cal: 280, p: 12, c: 6, f: 22, tip: "ผักกาดขาวฉ่ำน้ำ หมูกรอบกรุบกรอบ" },
  "ต้มเล้ง": { cal: 160, p: 18, c: 4, f: 7, tip: "น้ำซุปพริกขี้หนูมะนาวสดชื่น กระตุ้นภูมิคุ้มกัน" },
  "ส้มตำ": { cal: 120, p: 4, c: 24, f: 1, tip: "มะละกอดิบไฟเบอร์สูง ช่วยระบบขับถ่าย" },
  "ไก่ย่าง": { cal: 240, p: 28, c: 2, f: 13, tip: "โปรตีนสร้างกล้ามเนื้อเน้นๆ ไขมันปานกลาง" },
  "ราดหน้าหมู": { cal: 460, p: 22, c: 58, f: 14, tip: "คะน้ากรอบแคลเซียมสูง น้ำราดหน้านุ่มละมุน" },
  "ไก่ผัดเม็ดมะม่วง": { cal: 290, p: 20, c: 14, f: 17, tip: "ไขมันดีจากเม็ดมะม่วงหิมพานต์" },
  "ตุ๋นมะระยัดไส้": { cal: 140, p: 12, c: 6, f: 7, tip: "มะระช่วยควบคุมระดับน้ำตาลในเลือด" },
  "น้ำพริกกะปิ": { cal: 160, p: 8, c: 8, f: 9, tip: "แคลเซียมสูงจากกะปิ วิตามินจากผักสดหลากสี" },
  "ผัดกะเพราไก่": { cal: 280, p: 24, c: 6, f: 17, tip: "ใบกะเพราช่วยลดไขมันในเลือดและขับลม" }
};

function calculateMealNutrition(dish1, dish2, dessert, isSpecial) {
  let totalCal = RICE_1_SERVING.calories;
  let totalP = RICE_1_SERVING.protein;
  let totalC = RICE_1_SERVING.carbs;
  let totalF = RICE_1_SERVING.fat;
  let tips = [];

  const text = `${dish1 || ''} ${dish2 || ''} ${dessert || ''}`.toLowerCase();

  // จับคู่เมนู
  let matched = false;
  for (const [name, info] of Object.entries(DISH_DATABASE)) {
    if (text.includes(name.toLowerCase())) {
      totalCal += info.cal;
      totalP += info.p;
      totalC += info.c;
      totalF += info.f;
      if (info.tip && tips.length < 1) tips.push(info.tip);
      matched = true;
    }
  }

  // หากไม่มีใน DB ใช้การประมาณการอัจฉริยะ (Smart Fallback Estimation)
  if (!matched) {
    totalCal += 360;
    totalP += 20;
    totalC += 24;
    totalF += 14;
    tips.push("สารอาหารครบ 5 หมู่ อิ่มพอดีสำหรับ 1 เสิร์ฟ");
  }

  // ของหวาน
  if (dessert && dessert.trim() !== '' && dessert !== '-') {
    totalCal += 130;
    totalC += 24;
    totalF += 4;
  }

  // ปัดเศษตัวเลข
  totalCal = Math.round(totalCal / 5) * 5;
  totalP = Math.round(totalP);
  totalC = Math.round(totalC);
  totalF = Math.round(totalF);

  const runMin = Math.max(30, Math.round(totalCal / BURN_RATE_RUNNING));
  const walkMin = Math.max(50, Math.round(totalCal / BURN_RATE_WALKING));

  return {
    calories: totalCal,
    protein: totalP,
    carbs: totalC,
    fat: totalF,
    runningMinutes: runMin,
    walkingMinutes: walkMin,
    healthTip: tips[0] || "สารอาหารครบถ้วน อิ่มสบายท้อง"
  };
}

module.exports = { calculateMealNutrition };

if (require.main === module) {
  console.log("🍱 ทดสอบคำนวณเมนู: น้ำพริกอ่อง + ไข่ต้ม + ต้มจืดเต้าหู้ (รวมข้าว 1 ทัพพี)");
  console.log(calculateMealNutrition("น้ำพริกอ่อง + ไข่ต้ม + ผัก", "ต้มจืดเต้าหู้", "", false));
}
