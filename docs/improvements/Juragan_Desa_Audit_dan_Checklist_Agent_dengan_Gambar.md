Lampiran Visual — Juragan Desa
Ringkasan visual audit dan referensi arah pengembangan. Gambar konsep adalah ilustrasi referensi, bukan aset final yang
harus disalin persis.

Gambar 1. Papan referensi visual: temuan awal, arah art direction, contoh hierarki HUD, core loop, fitur, dan checklist prioritas.

Screenshot Build Saat Audit
Ini adalah bukti visual awal yang menjadi dasar kritik pada dokumen. Agent sebaiknya membandingkannya dengan build
terbaru dan tidak menganggap kondisi ini masih sama tanpa verifikasi.

Gambar 2. Screenshot game Juragan Desa yang diberikan untuk audit awal.

JURAGAN DESA

AUDIT GAMEPLAY, VISUAL, UX, DAN TECHNICAL QUALITY

Dokumen kerja untuk AI coding agent / game development agent

Tujuan: mengubah kritik awal berbasis screenshot menjadi daftar pemeriksaan dan pekerjaan yang
bisa diverifikasi di project Roblox.

STATUS AUDIT

BATASAN

Audit awal / visual-first.
Fokus utama: art direction, komposisi map, HUD, identitas
lokal, core loop, onboarding, ekonomi, multiplayer,
performa, dan keamanan.

Sumber utama hanya satu screenshot desktop dan
deskripsi konsep dari pemilik project. Sistem yang tidak
terlihat belum dinilai; jangan menganggapnya sudah ada
atau tidak ada.

Kesimpulan singkat

Konsep Juragan Desa punya potensi diferensiasi: farming simulator dengan ekonomi dan kehidupan
desa Indonesia. Namun screenshot saat ini menunjukkan bahasa visual yang belum konsisten, hierarki
UI yang lemah, komposisi lingkungan yang kurang terarah, dan identitas lokal yang masih lebih terlihat
sebagai dekorasi daripada sistem permainan.

Arah rekomendasi: jangan menambah banyak fitur dulu. Rapikan fondasi visual dan UI, lalu pastikan
satu siklus tanam–panen–jual–investasi terasa menyenangkan sebelum memperluas sistem.

Cara agent menggunakan dokumen ini

• Periksa project dan gameplay yang benar-benar ada sebelum mengubah apa pun.

• Petakan setiap temuan ke file, script, model, UI component, atau lokasi map yang relevan.

• Bedakan temuan yang terkonfirmasi dari dugaan yang perlu diuji.

• Kerjakan prioritas P0 terlebih dahulu. Jangan melakukan redesign besar tanpa memeriksa struktur

project dan mempertahankan fitur yang sudah berjalan.

• Setelah perubahan, berikan bukti: screenshot, video singkat, hasil playtest, atau ringkasan pengujian.

Prinsip kerja: audit ini adalah arahan desain, bukan izin untuk menghapus sistem atau mengubah scope secara sepihak.

JURAGAN DESA  |  AUDIT & AGENT CHECKLIST

Halaman 1

1. Temuan yang terlihat pada screenshot

Bagian ini hanya mencatat hal yang bisa diamati langsung. Agent perlu memverifikasi apakah kondisi
tersebut masih berlaku pada build terbaru.

Area

Temuan visual

Arah perbaikan

Art direction

Pohon/rumput bertekstur ramai, bangunan
low-poly sederhana, kios bertekstur kayu
dominan, avatar bergaya modern. Elemen
terasa memakai standar visual berbeda.

Pilih satu visual language. Rekomendasi awal:
stylized low-poly / cozy stylized, dengan
material, palet, tekstur, outline, dan proporsi
yang konsisten.

Visual noise

Tekstur rumput dan dedaunan cukup padat;
semak berulang; pohon besar di kiri
mendominasi foreground.

Kurangi detail yang tidak membantu. Sisakan
area visual tenang dan pastikan objek gameplay
lebih mudah dikenali daripada dekorasi.

Komposisi map

Pohon kiri dan kios biru kanan mengambil
banyak perhatian; karakter relatif kecil;
beberapa bangunan/label bertumpuk.

Susun foreground, midground, background. Dari
spawn, karakter, area pertanian, dan pusat
aktivitas harus mudah dikenali.

Bangunan

HUD kiri

HUD kanan

Bangunan tampak berupa bentuk geometris
sederhana dan belum semuanya punya
siluet/fungsi yang mudah dikenali.

Tambahkan ciri fungsional yang relevan:
kentongan/bangku pos ronda, etalase warung,
lapak pasar, papan balai desa, dan sebagainya.
Hindari dekorasi tanpa fungsi atau konteks.

Uang, rank, sack, Sus, dan reputation berada
dalam satu panel. Arti 'Sus' tidak jelas; hierarki
belum kuat.

Prioritaskan uang, kapasitas, dan objective. Beri
label yang mudah dipahami; jelaskan atau ganti
istilah yang ambigu.

Seeds dan Phone kecil; Board jauh lebih besar.
Perbedaan ukuran belum menunjukkan prioritas
penggunaan secara jelas.

Kelompokkan berdasarkan frekuensi: selalu
terlihat, sering dipakai, kontekstual, dan jarang
dipakai.

Inventory bawah

Tujuh komoditas tampil sebagai teks dengan
jumlah nol. Tidak jelas apakah ini quickbar atau
daftar inventory.

Pisahkan quickbar alat/benih dari inventory
seluruh komoditas. Gunakan ikon dan tampilkan
informasi yang relevan.

Notifikasi harga

'Chili prices are soaring! x3' mengindikasikan
event ekonomi, tetapi durasi, dampak, dan
tindakan pemain tidak jelas. Warna merah juga
bisa terbaca sebagai bahaya.

Tampilkan dampak, periode, dan peluang
tindakan. Gunakan warna sesuai makna:
kenaikan harga sebagai peluang bila memang
menguntungkan penjual.

Objective

Tidak terlihat tujuan aktif atau instruksi
tindakan pada screenshot.

Verifikasi apakah objective/tutorial tersedia. Jika
belum, tampilkan satu langkah berikutnya
secara kontekstual.

Catatan bahasa dan lokalitas

Format mata uang yang disarankan untuk konteks Indonesia adalah 'Rp 90.788'. Pertimbangkan
konsistensi istilah seperti Rank/Peringkat, Farmer/Petani, Sack/Karung, Reputation/Reputasi. Pilih
Bahasa Indonesia penuh atau bilingual yang disengaja; jangan mencampur tanpa aturan.

JURAGAN DESA  |  AUDIT & AGENT CHECKLIST

Halaman 2

2. Prioritas implementasi

Urutan ini sengaja menahan penambahan fitur sampai fondasi presentasi dan loop utama cukup kuat.

P0 — Fondasi yang harus dibereskan lebih dulu

P0-01 — Tentukan art direction
Buat satu halaman art bible: palet warna, material, tekstur, outline, proporsi, bentuk tanaman, gaya
bangunan, dan aturan pencahayaan. Pilihan awal yang direkomendasikan: stylized low-poly yang
hangat dan mudah dibaca.

P0-02 — Rapikan komposisi map dan spawn
Audit sudut pandang spawn. Pastikan karakter, lahan pertanian, dan pusat aktivitas terlihat. Kurangi
objek foreground yang menutup gameplay; atur jarak dan siluet landmark.

P0-03 — Redesign HUD
Bangun hierarki informasi. Uang/kapasitas/objective menjadi prioritas; menu lain muncul sesuai
konteks. Pastikan tombol tidak saling bersaing.

P0-04 — Definisikan inventory vs quickbar
Quickbar untuk alat/benih yang sedang dipakai; inventory untuk semua hasil panen dan kapasitas.
Hindari menampilkan daftar panjang item nol secara permanen.

P0-05 — Pastikan core loop bekerja
Tanam → rawat/tunggu → panen → jual → gunakan hasil untuk upgrade. Pastikan setiap langkah
memberi feedback dan keputusan, bukan hanya menunggu angka berubah.

P0-06 — Bangun first-time user experience
Pemain baru harus memahami aksi utama dan mendapat reward awal. Sasaran awal yang disarankan:
tutorial singkat sekitar 3–5 menit, bukan serangkaian dialog panjang.

P1 — Kedalaman dan rasa bermain

• Tambahkan feedback aksi: animasi tanam/panen, suara, perubahan visual tanaman, konfirmasi

transaksi, dan indikator inventory.

• Kembangkan pasar: harga komoditas, permintaan, tren, stok berlebih, pesanan NPC, dan event yang

mendorong keputusan.

• Buat progression short-term, mid-term, dan long-term: aktivitas per menit, upgrade beberapa sesi, lalu

ekspansi usaha/fasilitas.

• Hidupkan lingkungan dengan NPC dan ambient activity yang relevan, tanpa membebani performa.

• Uji fitur sosial yang sesuai tema: gotong royong, proyek desa, pasar antarpemain, dan kerja sama lahan.

P2 — Kualitas produk dan operasi

• Uji mobile, PC, resolusi berbeda, dan graphics quality rendah.

• Optimalkan model, tekstur, dedaunan transparan, jumlah Part, streaming, dan penggunaan ulang aset.

• Pastikan validasi ekonomi dilakukan server-side; uji DataStore, autosave, transaksi, dan pencegahan

duplikasi item.

• Gunakan analytics dan playtest untuk menemukan titik pemain berhenti, bukan hanya mengandalkan

opini internal.

• Rancang monetisasi kosmetik/convenience yang tidak sengaja membuat gameplay dasar terasa lambat

atau tidak adil.

JURAGAN DESA  |  AUDIT & AGENT CHECKLIST

Halaman 3

3. Arahan desain gameplay dan ekonomi

Core loop yang disarankan

Menanam → merawat dan memanen → menjual → memperoleh uang/XP/reputasi →
mengembangkan usaha → kembali bertani dengan kemampuan baru.

Jangan berhenti pada pola beli benih → tanam → tunggu → panen → jual yang diulang tanpa keputusan.
Pemain perlu memilih komoditas, mengatur waktu, memantau pasar, dan menentukan investasi.

Peran komoditas

Komoditas

Peran gameplay yang bisa diuji

Padi

Cabai

Komoditas stabil dengan hasil relatif konsisten.

Harga fluktuatif dan potensi keuntungan tinggi; cocok untuk menguji event pasar.

Singkong

Pertumbuhan relatif mudah dan margin menengah.

Kopi

Jagung

Siklus lebih lama dan nilai jual lebih tinggi.

Komoditas fleksibel dengan permintaan yang beragam.

Semua karakteristik di atas adalah hipotesis desain, bukan data balancing yang sudah terbukti. Agent tidak boleh
memasukkan angka final sebelum memeriksa sistem ekonomi yang ada dan melakukan simulasi.

Metrik balancing

Gunakan profit per minute sebagai salah satu indikator awal:

Profit per Minute = (Revenue − Total Cost) / Growth Time

Bandingkan dengan faktor lain: harga benih, jumlah hasil panen, biaya perawatan, variasi harga, risiko,
kapasitas inventory, dan interaksi pemain. Jangan sampai satu tanaman selalu menjadi pilihan terbaik
dalam semua situasi.

Sistem pasar yang disarankan

• Board menampilkan harga jual, tren harga, komoditas yang dicari, dan stok berlebih.

• Pesanan NPC memberi target kuantitas, tenggat, dan bonus yang jelas.

• Event harga menjelaskan apa yang berubah, berapa lama, dan siapa yang diuntungkan.

• Harga tidak boleh terasa acak tanpa sebab. Beri petunjuk yang bisa dipahami pemain.

• Uang perlu economic sinks yang bermakna: alat, gudang, kapasitas, lahan, kendaraan, fasilitas, atau

distribusi.

Progression dan reputasi

Rank dan reputation harus punya dampak. Contoh: reputasi membuka kontrak pedagang; rank
membuka komoditas atau alat; uang membuka kapasitas; kontribusi komunitas membuka fasilitas.
Hindari statistik yang hanya menjadi angka pajangan.

Waktu tunggu

Jika tanaman membutuhkan waktu tumbuh, sediakan aktivitas alternatif: kelola stok, penuhi pesanan,
antar barang, kumpulkan sumber daya, bantu pemain lain, atau kontribusi pada fasilitas desa. Waktu
tunggu seharusnya membuka pilihan, bukan menjadi penghalang kosong.

JURAGAN DESA  |  AUDIT & AGENT CHECKLIST

Halaman 4

4. Identitas Indonesia dan world-building

Identitas lokal harus masuk ke mekanisme, bukan hanya model bangunan atau
teks berbahasa Indonesia.

Elemen lingkungan yang dapat dipilih sesuai wilayah inspirasi

• Warung desa: transaksi kecil, kebutuhan harian, atau pesanan lokal.

• Pasar tradisional: jual-beli komoditas dan dinamika harga.

• Persawahan: pematang, irigasi, dan variasi tahap pertumbuhan.

• Balai desa: pengumuman, proyek komunitas, dan fasilitas publik.

• Pos ronda: misi ronda atau event keamanan jika relevan dengan gameplay.

Mekanisme lokal yang potensial

• Gotong royong memperbaiki irigasi atau membangun fasilitas.

• Pasar mingguan dengan permintaan komoditas yang berubah.

• Musim panen dan kalender komoditas.

• Koperasi untuk transaksi hasil panen dalam jumlah besar.

• Proyek desa yang membutuhkan kontribusi uang, barang, atau tenaga dari komunitas.

Pilih inspirasi regional yang jelas

Desa Indonesia sangat beragam. Tentukan wilayah inspirasi agar arsitektur, vegetasi, komoditas,
pakaian NPC, bahasa, dan soundscape terasa menyatu. Jangan mencampur semua simbol lokal tanpa
konteks.

World layout

• Foreground: dekorasi yang memberi kedalaman tetapi tidak menutup interaksi.

• Midground: lahan, pasar, dan aktivitas utama yang mudah dibaca.

• Background: bukit, rumah, sawah, atau landmark yang memberi skala.

• Setiap bangunan landmark harus punya fungsi atau alasan keberadaan yang jelas.

• Gunakan papan nama fisik, ikon lokasi, penanda arah, dan proximity prompt secara selektif; jangan

mengandalkan floating text untuk semuanya.

JURAGAN DESA  |  AUDIT & AGENT CHECKLIST

Halaman 5

5. UX, feedback, multiplayer, dan technical quality

First-time user experience

Langkah

Pengalaman yang dituju

Bukti yang perlu dicek

1. Spawn

Pemain langsung melihat lahan kecil, NPC, dan
satu tujuan.

Tujuan terlihat tanpa harus membuka banyak
menu.

2. Benih gratis

NPC memberi benih dan mengajarkan cara
menanam.

Pemain berhasil menanam tanpa kebingungan
kontrol.

3. Panen
pertama

4. Jual

Pemain melihat pertumbuhan/hasil dan mendapat
feedback.

Animasi, suara, dan inventory update bekerja.

Pemain belajar memakai pasar dan memahami
nilai barang.

Transaksi berhasil dan saldo diperbarui server.

5. Upgrade

Pemain membeli peningkatan pertama dan
memahami progres.

Manfaat upgrade terlihat, tujuan berikutnya
jelas.

Game feel dan audio

• Tanam: tanah berubah dan bibit muncul.

• Siram: animasi air dan suara percikan.

• Tumbuh: perubahan visual bisa dikenali.

• Panen: gerak petik, suara, dan feedback jumlah item.

• Jual/beli: konfirmasi transaksi, suara, dan update saldo.

• Naik rank: pencapaian terasa, tetapi tidak mengganggu permainan.

• Ambient: burung, jangkrik, angin sawah, pasar, kendaraan jauh, dan musik yang sesuai lokasi/waktu.

Multiplayer

• Prioritaskan interaksi sosial yang memperkuat tema: gotong royong, proyek desa, pasar pemain,

kompetisi panen, dan bantuan lahan.

• Lindungi progres pemain. Jangan izinkan pencurian atau griefing tanpa aturan dan persetujuan yang

jelas.

• Pastikan sistem transaksi dan kontribusi aman serta konsisten antar pemain.

Technical quality dan keamanan

• Client tidak boleh menentukan saldo, harga jual, jumlah item, atau kepemilikan lahan. Server

memvalidasi seluruh transaksi dan perubahan ekonomi.

• Validasi RemoteEvent: tipe data, rentang angka, kepemilikan item, jarak interaksi, cooldown, dan

konteks aksi.

• Uji DataStore/autosave, kegagalan penyimpanan, pemain keluar saat transaksi, duplikasi item, dan

pemulihan progres.

• Uji performa di perangkat kelas bawah. Pantau FPS, memory, jumlah instance, transparansi dedaunan,

dan beban animasi/NPC.

• Uji UI pada mobile, PC, resolusi berbeda, landscape, dan graphics quality rendah. Pastikan tombol

mudah disentuh dan tidak tertutup kontrol Roblox.

JURAGAN DESA  |  AUDIT & AGENT CHECKLIST

Halaman 6

6. Checklist verifikasi agent

Isi status setelah memeriksa project. Jangan menandai selesai hanya karena perubahan sudah ditulis;
jalankan game dan verifikasi hasilnya.

A. Discovery sebelum mengubah project

☐ Saya sudah memeriksa struktur project, script, model, UI, dan sistem yang sudah ada.

☐ Saya sudah mengidentifikasi fitur yang benar-benar berjalan dan fitur yang masih placeholder.

☐ Saya sudah memetakan temuan audit ke file/objek/lokasi yang spesifik.

☐ Saya tidak menghapus atau mengganti sistem yang berjalan tanpa alasan dan konfirmasi.

B. Art direction dan map

☐ Ada aturan visual yang konsisten untuk warna, material, tekstur, outline, pencahayaan, dan proporsi.

☐ Objek penting lebih mudah dikenali daripada dekorasi.

☐ Spawn memperlihatkan karakter, lahan, dan pusat aktivitas dengan jelas.

☐ Foreground tidak menutup jalur, karakter, atau interaksi.

☐ Bangunan utama punya siluet, fungsi, dan penanda lokasi yang jelas.

☐ Vegetasi dan dekorasi tidak berulang secara mencolok atau menimbulkan visual noise.

C. UI/UX

☐ Informasi utama punya hierarki yang jelas.

☐ Istilah ambigu seperti 'Sus' sudah dijelaskan atau diperbaiki.

☐ Format mata uang dan bahasa konsisten.

☐ Inventory dan quickbar punya fungsi yang berbeda dan jelas.

☐ UI tidak menutupi karakter atau area gameplay.

☐ Objective aktif terlihat tanpa pemain harus mencari-cari.

☐ Tombol dan teks tetap terbaca pada resolusi kecil dan mobile.

D. Gameplay dan ekonomi

☐ Pemain baru bisa menanam, memanen, menjual, dan menggunakan hasil penjualan.

☐ Setiap aksi utama memberikan feedback visual/audio yang sesuai.

☐ Setiap komoditas punya alasan untuk dipilih.

☐ Harga pasar menciptakan keputusan, bukan perubahan acak tanpa penjelasan.

☐ Uang memiliki penggunaan jangka pendek dan jangka panjang.

☐ Rank dan reputation memberi dampak nyata.

☐ Waktu tunggu menyediakan aktivitas alternatif.

☐ Tidak ada satu tanaman yang mendominasi semua pilihan tanpa trade-off.

E. Onboarding dan retention

☐ Pemain baru mendapat tujuan pertama yang jelas.

☐ Tutorial mengajarkan sambil bermain, bukan hanya melalui dialog.

☐ Pemain merasakan reward awal dengan cepat.

☐ Pemain tahu tujuan berikutnya setelah tutorial selesai.

☐ Progression memiliki target jangka pendek, menengah, dan panjang.

JURAGAN DESA  |  AUDIT & AGENT CHECKLIST

Halaman 7

F. Multiplayer dan technical

☐ Transaksi ekonomi divalidasi server-side.

☐ RemoteEvent divalidasi terhadap exploit dan input tidak sah.

☐ DataStore/autosave diuji termasuk kondisi gagal dan keluar mendadak.

☐ Tidak ada duplikasi item atau transaksi yang bisa dieksploitasi dalam pengujian.

☐ Performa diuji pada perangkat/setting rendah.

☐ UI dan kontrol diuji di mobile, PC, dan rasio layar berbeda.

G. Bukti dan regresi

☐ Ada screenshot sebelum/sesudah untuk perubahan visual dan UI.

☐ Ada video atau catatan playtest untuk core loop.

☐ Perubahan baru tidak merusak fitur lama.

☐ Bug yang ditemukan dicatat dengan langkah reproduksi.

☐ Agent melaporkan file yang diubah, alasan, risiko, dan pengujian yang dilakukan.

JURAGAN DESA  |  AUDIT & AGENT CHECKLIST

Halaman 8

7. Definition of Done dan instruksi kerja untuk
agent

Sebuah task dianggap selesai hanya jika:

• Perubahan sesuai prioritas dan tidak memperluas scope tanpa kebutuhan.

• Implementasi berjalan di Roblox Studio atau lingkungan test project yang digunakan.

• Tidak ada error baru yang diketahui pada output/log.

• Hasil visual/interaksi diverifikasi melalui screenshot atau playtest.

• Fitur lama yang terkait tetap berjalan.

• Agent menjelaskan keterbatasan, asumsi, dan pekerjaan lanjutan yang belum selesai.

Prompt yang bisa diberikan kepada AI agent

Peran: Bertindak sebagai senior Roblox game designer, UX designer, technical designer, dan reviewer
Luau.

Gunakan dokumen audit Juragan Desa ini sebagai arahan evaluasi. Mulailah dengan melakukan
discovery terhadap project yang tersedia. Jangan langsung mengubah banyak file. Identifikasi
struktur project, sistem yang sudah berjalan, placeholder, dan hubungan antarfitur.

Aturan:
1. Bedakan fakta yang ditemukan di project, temuan screenshot, dan hipotesis desain.
2. Jangan menganggap fitur yang tidak terlihat berarti belum ada. Cari dan verifikasi dahulu.
3. Jangan menghapus fitur atau mengganti arsitektur besar tanpa alasan yang jelas.
4. Kerjakan P0 terlebih dahulu dan pecah menjadi task kecil yang bisa diuji.
5. Untuk setiap task, laporkan: masalah, bukti/lokasi file atau objek, usulan, file yang akan diubah,
risiko, dan acceptance criteria.
6. Setelah implementasi, jalankan pengujian yang tersedia dan sertakan bukti visual atau hasil
playtest.
7. Prioritaskan konsistensi visual, keterbacaan UI, core loop, dan pengalaman pemain baru sebelum
menambah fitur baru.

Output awal yang diminta: (a) peta struktur project, (b) daftar fitur yang sudah ada dan statusnya, (c)
gap analysis terhadap P0–P2, (d) rekomendasi urutan task, dan (e) task pertama yang paling aman
untuk dikerjakan. Jangan mulai refactor besar sebelum hasil discovery dilaporkan.

Catatan akhir

Audit ini berasal dari satu screenshot desktop dan konsep yang dijelaskan pemilik project. Nilai visual
awal bukan skor kualitas final game. Gameplay, balancing, retention, keamanan, dan performa harus
diuji langsung pada project dan build yang berjalan.

Target utama: membuat satu siklus tanam–panen–jual yang jelas, memuaskan, dan
punya keputusan bermakna; dibungkus dunia desa Indonesia yang konsisten dan
mudah dibaca.

JURAGAN DESA  |  AUDIT & AGENT CHECKLIST

Halaman 9

