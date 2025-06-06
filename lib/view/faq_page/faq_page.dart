import 'package:flutter/material.dart';
import 'package:temulapak_app/assets/mycolor.dart';
import 'package:temulapak_app/model/faq/faq.dart';
import 'package:temulapak_app/view/widget/faq/faq_item_widget.dart';


class FaqPage extends StatefulWidget {
  const FaqPage({super.key});

  @override
  State<FaqPage> createState() => _FaqPageState();
}

class _FaqPageState extends State<FaqPage> {
  final List<FaqItem> faqItems = [
    FaqItem(
      question: "Apa itu TemuLapak?",
      answer:
          "TemuLapak adalah aplikasi mobile yang menghubungkan pembeli dengan pedagang keliling secara real-time. Aplikasi ini membantu Anda menemukan pedagang favorit di sekitar lokasi Anda.",
    ),
    FaqItem(
      question: "Bagaimana cara menemukan pedagang terdekat?",
      answer:
          "Buka halaman beranda, aktifkan lokasi GPS Anda, dan TemuLapak akan menampilkan daftar pedagang yang sedang berjualan di sekitar Anda beserta jarak dan jenis dagangannya.",
    ),
    FaqItem(
      question: "Apakah saya bisa chat dengan pedagang?",
      answer:
          "Ya! TemuLapak menyediakan fitur chat terintegrasi sehingga Anda bisa langsung berkomunikasi dengan pedagang untuk bertanya produk, melakukan pemesanan, atau bernegosiasi harga.",
    ),
    FaqItem(
      question: "Bagaimana cara menjadi penjual di TemuLapak?",
      answer:
          "Untuk menjadi penjual, silahkan hubungi tim support kami melalui menu 'Bantuan & Dukungan'. Tim kami akan membantu proses verifikasi dan pengaturan akun penjual Anda.",
    ),
    FaqItem(
      question: "Apakah lokasi saya aman?",
      answer:
          "TemuLapak mengutamakan privasi dan keamanan data. Lokasi Anda hanya digunakan untuk menampilkan pedagang terdekat dan tidak akan dibagikan kepada pihak ketiga tanpa persetujuan Anda.",
    ),
    FaqItem(
      question: "Bagaimana sistem pembayaran di TemuLapak?",
      answer:
          "Saat ini pembayaran dilakukan secara langsung dengan pedagang (cash). Fitur pembayaran digital sedang dalam pengembangan dan akan segera tersedia.",
    ),
    FaqItem(
      question: "Apa yang harus dilakukan jika ada masalah dengan pesanan?",
      answer:
          "Jika ada masalah dengan pesanan, Anda bisa melaporkannya melalui fitur chat dengan pedagang atau menghubungi tim support kami di menu 'Bantuan & Dukungan'.",
    ),
    FaqItem(
      question: "Bagaimana cara memberikan rating dan review?",
      answer:
          "Fitur rating dan review sedang dalam pengembangan. Nantinya Anda bisa memberikan penilaian dan ulasan untuk membantu pengguna lain menemukan pedagang terbaik.",
    ),
    FaqItem(
      question: "Apakah TemuLapak gratis?",
      answer:
          "Ya, TemuLapak gratis untuk digunakan oleh pembeli. Untuk pedagang, terdapat biaya berlangganan yang terjangkau untuk menggunakan fitur-fitur penjualan.",
    ),
    FaqItem(
      question: "Di wilayah mana saja TemuLapak tersedia?",
      answer:
          "Saat ini TemuLapak fokus melayani wilayah Jakarta dan sekitarnya. Kami berencana untuk memperluas jangkauan ke kota-kota besar lainnya di Indonesia.",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: MyColor.blackPlain),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'FAQ',
          style: TextStyle(
            color: MyColor.blackPlain,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: MyColor.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: MyColor.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.help_outline,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Frequently Asked Questions",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: MyColor.blackPlain,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Temukan jawaban untuk pertanyaan umum",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: faqItems.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
               itemBuilder: (context, index) {
                return FaqItemWidget(item: faqItems[index]);
              },
            ),
            const SizedBox(height: 30),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: MyColor.lightGrey,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.support_agent,
                    color: MyColor.orange,
                    size: 40,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Tidak menemukan jawaban?",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: MyColor.blackPlain,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Tim support kami siap membantu Anda",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


}

