import 'package:flutter/material.dart';
import 'package:temulapak_app/assets/mycolor.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

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
          'Tentang Aplikasi',
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
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: MyColor.orange.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Image.asset(
                      "lib/assets/icons/logoappTemuLapak.png",
                      width: 80,
                      height: 80,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "TemuLapak",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: MyColor.orange,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Versi 1.0.0",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Menghubungkan pembeli dengan pedagang keliling secara real-time",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            _buildSectionTitle("Tentang TemuLapak"),
            const SizedBox(height: 16),
            _buildInfoCard(
              "TemuLapak adalah aplikasi berbasis mobile yang menghubungkan pembeli dengan pedagang keliling secara real-time. Aplikasi ini memberikan solusi untuk tantangan lokasi pedagang yang sering berpindah-pindah.\n\nDengan fitur pelacakan lokasi, chat terintegrasi, dan informasi lengkap tentang produk, TemuLapak memudahkan konsumen menemukan pedagang favorit mereka sambil membantu pedagang keliling memperluas jangkauan bisnis.",
            ),

            const SizedBox(height: 30),

            _buildSectionTitle("Fitur Utama"),
            const SizedBox(height: 16),
            _buildFeatureList(),

            const SizedBox(height: 30),

            _buildSectionTitle("Informasi Developer"),
            const SizedBox(height: 16),
            _buildDeveloperCard(context),

            const SizedBox(height: 30),

            _buildSectionTitle("Legal & Kebijakan"),
            const SizedBox(height: 16),
            _buildLegalItem(
              context: context,
              icon: Icons.privacy_tip,
              title: "Kebijakan Privasi",
              content:
                  "TemuLapak berkomitmen melindungi privasi pengguna. Data lokasi dan informasi pribadi Anda hanya digunakan untuk meningkatkan pengalaman aplikasi dan tidak akan dibagikan kepada pihak ketiga tanpa persetujuan.",
            ),
            const SizedBox(height: 12),
            _buildLegalItem(
              context: context,
              icon: Icons.description,
              title: "Syarat & Ketentuan",
              content:
                  "Dengan menggunakan TemuLapak, Anda menyetujui syarat dan ketentuan yang berlaku. Pengguna bertanggung jawab atas keamanan akun dan aktivitas yang dilakukan melalui aplikasi ini.",
            ),
            const SizedBox(height: 12),
            _buildLegalItem(
              context: context,
              icon: Icons.security,
              title: "Keamanan Data",
              content:
                  "TemuLapak menggunakan enkripsi dan protokol keamanan terkini untuk melindungi data pengguna. Semua transaksi data dilakukan melalui koneksi yang aman dan terenkripsi.",
            ),

            const SizedBox(height: 40),

            Center(
              child: Column(
                children: [
                  Text(
                    "© 2025 TemuLapak",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: MyColor.blackPlain,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: MyColor.blackPlain,
      ),
    );
  }

  Widget _buildInfoCard(String content) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MyColor.lightGrey,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        textAlign: TextAlign.justify,
        content,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[700],
          height: 1.6,
        ),
      ),
    );
  }

  Widget _buildFeatureList() {
    final features = [
      "🗺️ Pelacakan lokasi pedagang real-time",
      "💬 Chat terintegrasi dengan pedagang",
      "🔍 Filter produk berdasarkan kategori",
      "📍 Notifikasi pedagang terdekat",
      "⭐ Rating dan review pedagang",
      "🔒 Keamanan data terjamin",
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MyColor.orange.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: MyColor.orange.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: features
            .map((feature) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        feature.substring(0, 2),
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          feature.substring(3),
                          style: TextStyle(
                            fontSize: 14,
                            color: MyColor.blackPlain,
                          ),
                        ),
                      ),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildDeveloperCard(BuildContext context) {
    final developers = [
      {
        'name': 'Shavarell Axel Ganendra',
        'email': 'shavarell.ganendra@binus.ac.id',
        'role': 'Lead Mobile Developer',
        'image':
            'https://firebasestorage.googleapis.com/v0/b/project-database-63eea.appspot.com/o/developer%2FIMG_2765_Cropped.JPG?alt=media&token=c4e4a87f-d578-41cc-94db-b5f9b260f719',
      },
      {
        'name': 'Bagas Dwi Putra Majid',
        'email': 'bagas.dwi@binus.ac.id',
        'role': 'Mobile Developer',
        'image':
            'https://firebasestorage.googleapis.com/v0/b/project-database-63eea.appspot.com/o/developer%2Fbagas.jpg?alt=media&token=65229bd6-f8c3-4d32-be2b-c83ef56958cb'
      },
      {
        'name': 'Gisela Audrey Limansagita',
        'email': 'gisela.limansagita@binus.ac.id',
        'role': 'Mobile Developer',
        'image':
            'https://firebasestorage.googleapis.com/v0/b/project-database-63eea.appspot.com/o/developer%2Fgisel.jpg?alt=media&token=e89559a1-26a4-46c4-8204-b616cd13a229',
      },
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MyColor.lightGrey,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: MyColor.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.code,
                  color: MyColor.orange,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Tim Pengembang TemuLapak",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: MyColor.blackPlain,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Startup teknologi yang fokus pada solusi ekonomi digital",
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

          const SizedBox(height: 20),

          ...developers.map((developer) => _buildDeveloperItem(
                context: context,
                name: developer['name']!,
                email: developer['email']!,
                role: developer['role']!,
                imagePath: developer['image']!,
              )),
        ],
      ),
    );
  }

  Widget _buildDeveloperItem({
    required BuildContext context,
    required String name,
    required String email,
    required String role,
    required String imagePath,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                  color: MyColor.orange.withValues(alpha: 0.3), width: 2),
            ),
            child: ClipOval(
              child: _buildDeveloperImage(imagePath),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: MyColor.blackPlain,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  role,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: MyColor.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    email,
                    style: TextStyle(
                      fontSize: 12,
                      color: MyColor.orange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeveloperImage(String imagePath) {
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return Image.network(
        imagePath,
        width: 60,
        height: 60,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[200],
            ),
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(MyColor.orange),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: MyColor.orange.withValues(alpha: 0.1),
            ),
            child: Icon(
              Icons.person,
              color: MyColor.orange,
              size: 30,
            ),
          );
        },
      );
    } else {
      return Image.asset(
        imagePath,
        width: 60,
        height: 60,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: MyColor.orange.withValues(alpha: 0.1),
            ),
            child: Icon(
              Icons.person,
              color: MyColor.orange,
              size: 30,
            ),
          );
        },
      );
    }
  }

  Widget _buildLegalItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showLegalDialog(context, title, content),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: MyColor.orange, size: 20),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: MyColor.blackPlain,
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLegalDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: MyColor.blackPlain,
          ),
        ),
        content: SingleChildScrollView(
          child: Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: MyColor.orange,
            ),
            child: const Text(
              'Tutup',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
