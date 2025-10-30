#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Telegram Auto Add Contact to Group
Author: dika
GitHub: https://github.com/oscaroffc
"""

import asyncio
import random
from telethon.sync import TelegramClient
from telethon.tl.functions.channels import InviteToChannelRequest
from telethon.tl.types import InputPeerUser
from telethon.errors import (
    FloodWaitError, 
    UserPrivacyRestrictedError,
    UserNotMutualContactError,
    PeerFloodError,
    UserBannedInChannelError,
    UserAlreadyParticipantError
)
import os
import glob
from datetime import datetime

# KONFIGURASI API - ISI DENGAN API ANDA
API_ID = '13451379'  # Ganti dengan API ID Anda
API_HASH = 'abbab70cf98039c05736d9c9fba38218'  # Ganti dengan API Hash Anda

class TelegramAdder:
    def __init__(self):
        self.client = None
        self.session_name = ""
        self.phone = ""
        self.filter_type = ""
        self.target_group = ""
        self.delay = 60
    
    def clear_screen(self):
        os.system('clear' if os.name != 'nt' else 'cls')
    
    def print_banner(self):
        self.clear_screen()
        print("=" * 55)
        print("     TELEGRAM AUTO ADD CONTACT TO GROUP")
        print("=" * 55)
        print("  Script by: dika")
        print("  GitHub: https://github.com/oscaroffc")
        print("=" * 55)
        print()
    
    def get_existing_sessions(self):
        """Ambil daftar session yang sudah ada"""
        sessions = []
        for file in glob.glob("*.session"):
            session_name = file.replace(".session", "")
            sessions.append(session_name)
        return sessions
    
    def select_or_create_session(self):
        """Pilih session existing atau buat baru"""
        self.print_banner()
        existing_sessions = self.get_existing_sessions()
        
        if existing_sessions:
            print("📂 SESSION TERSIMPAN\n")
            for idx, session in enumerate(existing_sessions, 1):
                print(f"{idx}. {session}")
            print(f"{len(existing_sessions) + 1}. Buat Session Baru")
            
            while True:
                try:
                    choice = input(f"\nPilih session (1-{len(existing_sessions) + 1}): ").strip()
                    choice_num = int(choice)
                    
                    if 1 <= choice_num <= len(existing_sessions):
                        self.session_name = existing_sessions[choice_num - 1]
                        print(f"\n✓ Menggunakan session: {self.session_name}")
                        return True  # Use existing session
                    elif choice_num == len(existing_sessions) + 1:
                        return False  # Create new session
                    else:
                        print("✗ Pilihan tidak valid!")
                except:
                    print("✗ Input tidak valid!")
        else:
            print("📂 SESSION\n")
            print("Belum ada session tersimpan.")
            print("Silakan buat session baru.\n")
            input("Tekan Enter untuk melanjutkan...")
            return False  # Create new session
    
    async def login_session(self):
        """Login dengan input step by step"""
        use_existing = self.select_or_create_session()
        
        if not use_existing:
            # Buat session baru
            self.print_banner()
            print("🔐 BUAT SESSION BARU\n")
            
            # 1. Nama Session
            self.session_name = input("Nama Session: ").strip()
            
            # 2. Nomor Telepon (semua negara)
            self.phone = input("Nomor Telepon (contoh: +6281234567890): ").strip()
        
        # Inisialisasi client
        self.client = TelegramClient(self.session_name, API_ID, API_HASH)
        await self.client.connect()
        
        # Cek apakah sudah login
        if not await self.client.is_user_authorized():
            if use_existing:
                print("\n⚠️  Session expired atau tidak valid!")
                print("Silakan login ulang.\n")
                self.phone = input("Nomor Telepon: ").strip()
            
            print(f"\n📨 Mengirim kode OTP ke {self.phone}...")
            await self.client.send_code_request(self.phone)
            
            # 3. Input OTP
            code = input("OTP: ").strip()
            
            try:
                await self.client.sign_in(self.phone, code)
            except Exception as e:
                if "Two-steps verification" in str(e) or "2FA" in str(e):
                    # 4. Jika ada 2FA
                    password = input("2FA (Password): ").strip()
                    await self.client.sign_in(password=password)
                else:
                    print(f"\n✗ Error saat login: {e}")
                    return False
        
        me = await self.client.get_me()
        print(f"\n✓ Login Berhasil!")
        print(f"  Nama: {me.first_name} {me.last_name or ''}")
        print(f"  Username: @{me.username or 'Tidak ada'}")
        print(f"  Phone: {me.phone}")
        print(f"  Session: {self.session_name}.session")
        
        input("\nTekan Enter untuk melanjutkan...")
        return True
    
    def input_delay(self):
        """Input delay per kontak"""
        self.print_banner()
        print("⏱️  SETTING DELAY\n")
        
        try:
            self.delay = int(input("Delay per 1 kontak (detik): ").strip())
            
            if self.delay < 30:
                print("\n⚠️  Warning: Delay terlalu cepat bisa menyebabkan akun banned!")
                print("Rekomendasi minimal: 60 detik")
        except:
            self.delay = 60
            print(f"Input tidak valid. Menggunakan default: {self.delay} detik")
        
        print(f"\n✓ Delay diset: {self.delay} detik per kontak")
        input("\nTekan Enter untuk melanjutkan...")
    
    def select_filter_type(self):
        """Menu pilihan filter kontak"""
        self.print_banner()
        print("📋 PILIH TIPE KONTAK\n")
        print("1. All (Semua Kontak)")
        print("2. Mutual (Kontak yang menyimpan nomor Anda)")
        print("3. Non-Mutual (Kontak yang tidak menyimpan nomor Anda)")
        
        while True:
            choice = input("\nPilihan: ").strip()
            if choice == '1':
                self.filter_type = 'all'
                break
            elif choice == '2':
                self.filter_type = 'mutual'
                break
            elif choice == '3':
                self.filter_type = 'nonmutual'
                break
            else:
                print("✗ Pilihan tidak valid! Pilih 1/2/3")
        
        print(f"\n✓ Dipilih: {self.filter_type.upper()}")
        input("\nTekan Enter untuk melanjutkan...")
    
    def input_group(self):
        """Input link grup"""
        self.print_banner()
        print("🎯 INPUT LINK GROUP\n")
        print("Format yang didukung:")
        print("  • Link Public  : https://t.me/namagrup")
        print("  • Link Private : https://t.me/+AbCdEfGhIjKlMn")
        print("  • Username     : @namagrup")
        print("  • ID Grup      : -1001234567890")
        
        self.target_group = input("\nInput Link Group (Private/Public): ").strip()
        
        print(f"\n✓ Target Group: {self.target_group}")
        input("\nTekan Enter untuk melanjutkan...")
    
    async def get_contacts(self):
        """Ambil daftar kontak berdasarkan filter"""
        from telethon.tl.functions.contacts import GetContactsRequest
        
        print(f"\n📋 Mengambil kontak ({self.filter_type})...")
        
        # Ambil semua kontak
        result = await self.client(GetContactsRequest(hash=0))
        contacts = result.users
        
        if self.filter_type == 'all':
            return contacts
        elif self.filter_type == 'mutual':
            filtered = [c for c in contacts if c.mutual_contact]
            return filtered
        elif self.filter_type == 'nonmutual':
            filtered = [c for c in contacts if not c.mutual_contact]
            return filtered
        
        return contacts
    
    def show_summary(self):
        """Tampilkan ringkasan sebelum mulai"""
        self.print_banner()
        print("📊 RINGKASAN PENGATURAN\n")
        print(f"Session      : {self.session_name}.session")
        print(f"Tipe Kontak  : {self.filter_type.upper()}")
        print(f"Target Group : {self.target_group}")
        print(f"Delay        : {self.delay} detik per kontak")
        print("\n" + "=" * 55)
    
    async def add_users_to_group(self):
        """Proses menambahkan users ke grup"""
        
        # Ambil grup target
        try:
            print(f"\n🔍 Mencari grup target...")
            target_group_entity = await self.client.get_entity(self.target_group)
            print(f"✓ Grup ditemukan: {target_group_entity.title}")
        except Exception as e:
            print(f"✗ Error mendapatkan grup: {e}")
            return
        
        # Ambil kontak sesuai filter
        contacts = await self.get_contacts()
        print(f"✓ Total kontak ditemukan: {len(contacts)}")
        
        if len(contacts) == 0:
            print("\n✗ Tidak ada kontak yang ditemukan!")
            return
        
        # Statistik
        success_count = 0
        failed_count = 0
        skipped_count = 0
        
        print(f"\n🚀 Memulai proses...")
        print("=" * 55 + "\n")
        
        for idx, user in enumerate(contacts, 1):
            try:
                # Tampilkan info user
                user_name = f"{user.first_name} {user.last_name or ''}".strip()
                username_str = f"@{user.username}" if user.username else "no_username"
                
                print(f"[{idx}/{len(contacts)}] {user_name} ({username_str})")
                
                # Tambahkan user ke grup
                await self.client(InviteToChannelRequest(
                    target_group_entity,
                    [user]
                ))
                
                success_count += 1
                print(f"  ✓ Berhasil ditambahkan")
                
            except UserAlreadyParticipantError:
                skipped_count += 1
                print(f"  ⊙ Sudah menjadi member")
                
            except UserPrivacyRestrictedError:
                failed_count += 1
                print(f"  ✗ Privacy settings tidak mengizinkan")
                
            except UserNotMutualContactError:
                failed_count += 1
                print(f"  ✗ Bukan mutual contact")
                
            except PeerFloodError:
                print(f"\n  ⚠️  FLOOD ERROR DETECTED!")
                print(f"  Terlalu banyak request. Akun Anda dibatasi sementara.")
                print(f"  Tunggu 1-24 jam sebelum mencoba lagi.")
                break
                
            except FloodWaitError as e:
                wait_time = e.seconds
                print(f"  ⏳ Flood wait: {wait_time} detik")
                await asyncio.sleep(wait_time)
                continue
                
            except UserBannedInChannelError:
                failed_count += 1
                print(f"  ✗ User dibanned dari grup")
                
            except Exception as e:
                failed_count += 1
                error_msg = str(e)[:60]
                print(f"  ✗ Error: {error_msg}")
            
            # Delay sebelum add user berikutnya
            if idx < len(contacts):
                print(f"  ⏱️  Menunggu {self.delay} detik...\n")
                await asyncio.sleep(self.delay)
        
        # Tampilkan hasil akhir
        print("\n" + "=" * 55)
        print("✅ PROSES SELESAI")
        print("=" * 55)
        print(f"Berhasil ditambahkan : {success_count}")
        print(f"Sudah member        : {skipped_count}")
        print(f"Gagal               : {failed_count}")
        print(f"Total diproses      : {len(contacts)}")
        print(f"\n💾 Session tersimpan: {self.session_name}.session")
        print(f"   Besok bisa langsung pilih session ini tanpa login lagi!")
        print("=" * 55)
    
    async def run(self):
        """Main program flow"""
        try:
            # Step 1: Login atau Pilih Session
            if not await self.login_session():
                return
            
            # Step 2: Input Delay
            self.input_delay()
            
            # Step 3: Pilih Filter Kontak
            self.select_filter_type()
            
            # Step 4: Input Grup Target
            self.input_group()
            
            # Step 5: Tampilkan Ringkasan
            self.show_summary()
            
            # Step 6: Konfirmasi Mulai
            print("\n⚠️  Tekan ENTER untuk mulai menambahkan kontak ke grup")
            input("   atau CTRL+C untuk membatalkan...\n")
            
            # Step 7: Mulai Proses
            await self.add_users_to_group()
            
        except KeyboardInterrupt:
            print("\n\n⚠️  Program dibatalkan oleh user")
        except Exception as e:
            print(f"\n✗ Error: {e}")
        finally:
            if self.client:
                await self.client.disconnect()
                print("\n✓ Disconnected")

# Main execution
if __name__ == "__main__":
    print("\n" + "=" * 55)
    print("  TELEGRAM AUTO ADD CONTACT TO GROUP")
    print("=" * 55)
    print("  Script by: oscaroffc")
    print("  GitHub: https://github.com/oscaroffc")
    print("=" * 55)
    print("\n⚠️  PENTING!")
    print("  • Isi API_ID dan API_HASH di baris 28-29")
    print("  • Dapatkan di: https://my.telegram.org/apps")
    print("  • Gunakan delay minimal 60 detik untuk keamanan")
    print("\n" + "=" * 55 + "\n")
    
    input("Tekan ENTER untuk mulai...")
    
    adder = TelegramAdder()
    asyncio.run(adder.run())
