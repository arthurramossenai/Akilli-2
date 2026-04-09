const { createClient } = require('@supabase/supabase-js');

const SUPABASE_URL = "https://sxtvfugrdtefosjvaehl.supabase.co";
const SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InN4dHZmdWdyZHRlZm9zanZhZWhsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU3NDMxMTcsImV4cCI6MjA5MTMxOTExN30.GbPCibphURle3mpbCjjkBwZm0Yl_hS2CZYjQ-JS8dhU"; 

const supabase = createClient(SUPABASE_URL, SUPABASE_KEY);

console.log('✅ SUCESSO: Cliente do Supabase configurado (Backend)!');

module.exports = supabase;
