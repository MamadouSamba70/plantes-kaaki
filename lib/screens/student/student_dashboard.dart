import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/scan_provider.dart';
import '../../models/scan.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  late AnimationController _animCtrl;
  late Animation<double> _fadeIn;

  // Academic Disease Data (Fiches Maladies)
  final List<Map<String, String>> _diseases = [
    {
      'name': 'Sigatoka Noire',
      'scientificName': 'Mycosphaerella fijiensis',
      'type': 'Fongique',
      'description': 'La Sigatoka noire est l\'une des maladies foliaires les plus destructrices affectant les bananiers à l\'échelle mondiale. Elle réduit drastiquement la surface foliaire active et nuit à la photosynthèse, entraînant une diminution significative du rendement et du poids des régimes.',
      'symptoms': 'Apparition de petites stries de couleur rouille sur la face inférieure de la feuille (stade 1). Ces stries s\'élargissent et brunissent pour former des taches nécrotiques elliptiques sombres avec un centre gris et un halo jaune caractéristique.',
      'cycle': 'Le champignon se propage principalement par des ascopores transportées par le vent en période humide, ou par des conidies dispersées par les gouttes de pluie. L\'humidité foliaire et les températures chaudes favorisent la germination.',
      'prevention': 'Drainage adéquat du sol, contrôle de la densité de plantation pour favoriser la circulation de l\'air, et élimination régulière (effeuillage) des portions de feuilles infectées pour réduire les sources d\'inoculum.',
      'treatment': 'Application ciblée de fongicides systémiques ou de contact en alternance pour éviter la résistance, combinée à des applications d\'huiles minérales horticoles protectrices.',
    },
    {
      'name': 'Flétrissement Bactérien (Moko)',
      'scientificName': 'Ralstonia solanacearum (Race 2)',
      'type': 'Bactérien',
      'description': 'Le Moko est une maladie bactérienne vasculaire extrêmement contagieuse qui s\'attaque au système de transport de la sève du bananier. Sans intervention rapide, elle décime les parcelles entières.',
      'symptoms': 'Flétrissement et jaunissement rapide des jeunes feuilles internes, qui se brisent et sèchent. Les fruits mûrissent prématurément de façon irrégulière et présentent une pourriture interne sèche et noire.',
      'cycle': 'La bactérie survit dans le sol et pénètre par les blessures des racines ou du pseudo-tronc. Elle se propage également par les outils de taille non désinfectés ou par les insectes visitant l\'inflorescence mâle.',
      'prevention': 'Désinfection rigoureuse des outils (machettes, couteaux) à l\'aide d\'une solution désinfectante appropriée. Coupe systématique des bourgeons mâles après la formation des fruits pour empêcher la transmission par les insectes.',
      'treatment': 'Aucun traitement chimique curatif n\'est efficace. Les plants infectés doivent être isolés, éliminés avec soin, et la zone doit être mise en quarantaine sous traitement herbicide/chaux pour détruire toute trace bactérienne.',
    },
    {
      'name': 'Maladie de Panama',
      'scientificName': 'Fusarium oxysporum f. sp. cubense',
      'type': 'Fongique',
      'description': 'La maladie de Panama (ou fusariose) est une affection vasculaire provoquée par un champignon tellurique (du sol) extrêmement persistant, capable de survivre plusieurs décennies dans la terre sans hôte.',
      'symptoms': 'Jaunissement progressif des bords des feuilles les plus anciennes, qui se propage vers la nervure centrale. Les pétioles faiblissent, provoquant l\'effondrement des feuilles qui pendent en jupe autour du pseudo-tronc.',
      'cycle': 'Le champignon s\'introduit par les racines, colonise le xylème et bloque le transport de l\'eau et des nutriments. Les chlamydospores résistent aux conditions défavorables dans le sol.',
      'prevention': 'Utilisation exclusive de vitroplants sains et certifiés. Mise en place de protocoles stricts de biosécurité à l\'entrée des exploitations (pédiluves, désinfection des roues).',
      'treatment': 'Incurable dans le sol. La gestion repose sur l\'utilisation de variétés résistantes adaptées et sur la mise en quarantaine stricte des zones contaminées.',
    },
    {
      'name': 'Anthracnose des Fruits',
      'scientificName': 'Colletotrichum musae',
      'type': 'Fongique',
      'description': 'L\'anthracnose affecte principalement la qualité visuelle et gustative des fruits, en particulier pendant la phase de post-récolte et de transport commercial.',
      'symptoms': 'Présence de petites taches noires et circulaires sur la peau des bananes en cours de maturation. Ces taches s\'étendent, s\'affaissent et se recouvrent parfois d\'un duvet de spores de couleur rose ou saumonée.',
      'cycle': 'Les spores du champignon contaminent le fruit jeune au champ. Elles restent à l\'état latent (quiescent) jusqu\'à ce que le fruit commence à mûrir et que les défenses naturelles de la peau diminuent.',
      'prevention': 'Manipulation délicate lors de la récolte et du conditionnement pour éviter les blessures physiques. Nettoyage régulier de la bananeraie pour éliminer les feuilles mortes abritant les spores.',
      'treatment': 'Lavage des fruits après récolte dans des bains d\'eau propre (parfois additionnée de traitements biologiques protecteurs) et maintien d\'une chaîne de froid stricte pendant le transport.',
    },
    {
      'name': 'Pourriture des Racines',
      'scientificName': 'Complexe fongique / Nématodes',
      'type': 'Racinaire',
      'description': 'La pourriture racinaire est souvent causée par l\'action conjointe de champignons pathogènes du sol (tels que Pythium ou Rhizoctonia) et de nématodes phytophages, particulièrement dans les sols mal drainés.',
      'symptoms': 'Croissance générale ralentie, feuilles présentant des signes de carence (jaunissement) et affaiblissement de l\'ancrage au sol, rendant la plante très sensible à la verse sous l\'effet du vent.',
      'cycle': 'Les agents pathogènes profitent de la saturation en eau du sol pour attaquer et détruire les poils absorbants et les tissus racinaires secondaires.',
      'prevention': 'Amélioration du drainage de la parcelle, apport régulier de matière organique pour stimuler la microflore bénéfique, et rotation des cultures.',
      'treatment': 'Application de nématicides biologiques ou de traitements fongicides du sol spécifiques en cas d\'infestation avérée.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fadeIn = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });

    // Fetch user diagnostic history
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.user != null) {
        Provider.of<ScanProvider>(context, listen: false).fetchHistory(auth.user!.uid);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeIn,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header Zone ────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bonjour, ${user?.fullName.split(' ').first ?? 'Étudiant'}',
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Espace d\'Apprentissage Académique',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => context.go('/profile'),
                      child: CircleAvatar(
                        radius: 22,
                        backgroundColor: AppColors.primary.withOpacity(0.08),
                        child: Text(
                          user?.fullName.isNotEmpty == true ? user!.fullName[0].toUpperCase() : 'E',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Tab Bar Indicator ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE8EBE8)),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: AppColors.textSecondary,
                    dividerColor: Colors.transparent,
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    tabs: const [
                      Tab(text: 'Fiches Maladies'),
                      Tab(text: 'Scan Éducatif'),
                    ],
                  ),
                ),
              ),

              // ── Tab Views ──────────────────────────────────────────────────
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildDiseasesView(isTablet),
                    _buildScanView(isTablet),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary.withOpacity(0.6),
        backgroundColor: Colors.white,
        elevation: 8,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded, size: 22), label: 'Tableau'),
          BottomNavigationBarItem(icon: Icon(Icons.camera_alt_outlined, size: 22), label: 'Scanner'),
          BottomNavigationBarItem(icon: Icon(Icons.history_outlined, size: 22), label: 'Historique'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded, size: 22), label: 'Profil'),
        ],
        onTap: (index) {
          if (index == 1) context.go('/scan');
          if (index == 2) context.go('/history');
          if (index == 3) context.go('/profile');
        },
      ),
    );
  }

  // ── VIEW 1 : DISEASES LIST (FICHES MALADIES) ──────────────────────────────
  Widget _buildDiseasesView(bool isTablet) {
    final filtered = _diseases.where((d) {
      final name = d['name']!.toLowerCase();
      final sci = d['scientificName']!.toLowerCase();
      final type = d['type']!.toLowerCase();
      return name.contains(_searchQuery) || sci.contains(_searchQuery) || type.contains(_searchQuery);
    }).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Search Field
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Rechercher une fiche ou pathologie...',
              prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () => _searchController.clear(),
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              filled: true,
              fillColor: Colors.white,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE8EBE8)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Disease List
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off_rounded, size: 48, color: AppColors.textSecondary.withOpacity(0.5)),
                        const SizedBox(height: 12),
                        const Text(
                          'Aucune fiche ne correspond à votre recherche.',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE8EBE8)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.01),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: InkWell(
                            onTap: () => _showDiseaseDetailBottomSheet(item),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              item['name']!,
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppColors.primary.withOpacity(0.08),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                item['type']!,
                                                style: const TextStyle(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.primary,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          item['scientificName']!,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontStyle: FontStyle.italic,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          item['description']!,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondary.withOpacity(0.9),
                                            height: 1.4,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 14,
                                    color: AppColors.textSecondary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ── VIEW 2 : EDUCATIONAL SCAN SYSTEM (SCAN ÉDUCATIF) ──────────────────────
  Widget _buildScanView(bool isTablet) {
    final scanProvider = Provider.of<ScanProvider>(context);
    final history = scanProvider.history;

    return RefreshIndicator(
      onRefresh: () async {
        final auth = Provider.of<AuthProvider>(context, listen: false);
        if (auth.user != null) {
          await scanProvider.fetchHistory(auth.user!.uid);
        }
      },
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Study Mode Banner Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE8EBE8)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.01),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.08),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.school_rounded, color: AppColors.primary, size: 22),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Outil de Diagnostic Terrain',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Utilisez l\'appareil photo de votre smartphone pour diagnostiquer les anomalies foliaires et collecter des observations d\'apprentissage.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.photo_camera_rounded, size: 18),
                    label: const Text('Lancer le Scan Éducatif', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    onPressed: () => context.go('/scan'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Diagnostic Best Practices
            const Text(
              'Règles pour un bon diagnostic',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE8EBE8)),
              ),
              child: Column(
                children: [
                  _buildPracticeRow(Icons.light_mode_outlined, 'Lumière naturelle', 'Prenez les photos sous une lumière claire mais évitez les reflets intenses du soleil direct.'),
                  const Divider(height: 20, color: Color(0xFFE8EBE8)),
                  _buildPracticeRow(Icons.center_focus_strong_outlined, 'Cadrage de près', 'Centrez l\'anomalie de la feuille à une distance de 15 à 20 centimètres.'),
                  const Divider(height: 20, color: Color(0xFFE8EBE8)),
                  _buildPracticeRow(Icons.camera_outlined, 'Netteté indispensable', 'Stabilisez votre appareil afin d\'éviter le flou de bougé lors du déclenchement.'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Recent Diagnostics Logs (Recent Scans)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Mes derniers diagnostics',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (history.isNotEmpty)
                  TextButton(
                    onPressed: () => context.go('/history'),
                    child: const Text(
                      'Voir tout',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            if (scanProvider.isLoadingHistory)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 30.0),
                child: Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2)),
              )
            else if (history.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE8EBE8)),
                ),
                child: const Center(
                  child: Text(
                    'Aucun diagnostic enregistré dans votre historique.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: history.length > 3 ? 3 : history.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (ctx, idx) {
                  final scan = history[idx];
                  final isHealthy = scan.disease.toLowerCase().contains('sain');
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE8EBE8)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 36,
                          decoration: BoxDecoration(
                            color: isHealthy ? AppColors.success : AppColors.danger,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                scan.disease,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Confiance: ${(scan.confidence * 100).toStringAsFixed(0)}% • ${DateFormat('dd/MM/yyyy HH:mm').format(scan.createdAt)}',
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.textSecondary),
                          onPressed: () {
                            scanProvider.clearImage();
                            scanProvider.setMockResult(scan);
                            context.push('/result');
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPracticeRow(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── DETAIL BOTTOM SHEET (FICHE TECHNIQUE MALADIE) ──────────────────────────
  void _showDiseaseDetailBottomSheet(Map<String, String> item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: DraggableScrollableSheet(
            initialChildSize: 0.8,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder: (context, scrollController) {
              return SingleChildScrollView(
                controller: scrollController,
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Handle Bar
                    Center(
                      child: Container(
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8EBE8),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Header Row
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['name']!,
                                style: const TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item['scientificName']!,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontStyle: FontStyle.italic,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.primary.withOpacity(0.15)),
                          ),
                          child: Text(
                            item['type']!,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Description Block
                    _buildSectionHeader('Description générale', Icons.info_outline_rounded),
                    const SizedBox(height: 6),
                    Text(
                      item['description']!,
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
                    ),
                    const SizedBox(height: 20),

                    // Symptoms Block
                    _buildSectionHeader('Symptômes typiques', Icons.remove_red_eye_outlined),
                    const SizedBox(height: 6),
                    Text(
                      item['symptoms']!,
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
                    ),
                    const SizedBox(height: 20),

                    // Biological Cycle Block
                    _buildSectionHeader('Cycle biologique / Causes', Icons.history_edu_outlined),
                    const SizedBox(height: 6),
                    Text(
                      item['cycle']!,
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
                    ),
                    const SizedBox(height: 20),

                    // Prevention Block
                    _buildSectionHeader('Méthodes de prévention (Prophylaxie)', Icons.shield_outlined),
                    const SizedBox(height: 6),
                    Text(
                      item['prevention']!,
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
                    ),
                    const SizedBox(height: 20),

                    // Treatment Block
                    _buildSectionHeader('Traitements recommandés', Icons.healing_outlined),
                    const SizedBox(height: 6),
                    Text(
                      item['treatment']!,
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
                    ),
                    const SizedBox(height: 28),

                    // Close Button
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Fermer la fiche', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
