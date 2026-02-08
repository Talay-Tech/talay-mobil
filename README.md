# 📱 Talay

Modern takım yönetimi mobil uygulaması.

## ✨ Özellikler

### 👥 Kullanıcılar İçin
- **Dashboard** - Özet bilgiler ve hızlı erişim
- **Kasa** - Gelir/gider takibi ve grafikler
- **Görevler** - Atanan görevleri görüntüleme
- **Mesajlaşma** - Gerçek zamanlı sohbet
- **Haberler** - RSS feed tabanlı haberler
- **Duyurular** - Takım duyuruları

### 👨‍💼 Yöneticiler İçin
- Kullanıcı yönetimi
- Görev oluşturma ve atama
- Kasa işlemleri (ekleme/silme)
- Duyuru yayınlama
- RSS kaynak yönetimi

## 🛠️ Teknolojiler

| Bileşen | Teknoloji |
|---------|-----------|
| Mobil | Flutter |
| Backend | Supabase |
| State | Riverpod |
| Admin Panel | Next.js |

## 🚀 Kurulum

### Mobil Uygulama
```bash
flutter pub get
flutter run
```

### Admin Panel
```bash
cd admin
npm install
npm run dev
```

## 📁 Proje Yapısı
```
lib/
├── models/        # Veri modelleri
├── screens/       # Ekranlar
│   ├── admin/     # Yönetici ekranları
│   └── member/    # Üye ekranları
├── services/      # İş mantığı
└── widgets/       # Yeniden kullanılabilir bileşenler
```

## 📖 Dokümantasyon

Detaylı bilgi için [TALAY_RAPOR.md](TALAY_RAPOR.md) dosyasına bakın.

## 📄 Lisans

Özel Proje © 2026
