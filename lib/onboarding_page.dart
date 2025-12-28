import 'package:flutter/material.dart';
import 'welcome_page.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  _OnboardingPageState createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int currentPage = 0;

  List<Map<String, String>> onboardingData = [
    {
      "title":
          "Nikmati kemudahan berinteraksi dan berdiskusi langsung dengan mentormu yang mana saja melalui platform yang intuitif dan interaktif.",
      "image": "assets/onboarding1.png",
    },
    {
      "title":
          "Akses ribuan pengajar ahli dari berbagai bidang yang siap membimbingmu. Belajar jadi lebih terarah dengan kurikulum yang personal dan fleksibel.",
      "image": "assets/onboarding2.png",
    },
    {
      "title":
          "Pantau perkembangan belajarmu secara nyata. Bersama Mentorly, setiap langkah kecilmu akan membawamu lebih dekat ke puncak kesuksesan.",
      "image": "assets/onboarding3.png",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    currentPage = index;
                  });
                },
                itemCount: onboardingData.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.all(30),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 280,
                          height: 280,
                          decoration: BoxDecoration(
                            color: Colors.blue[700],
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Icon(
                              index == 0
                                  ? Icons.school
                                  : index == 1
                                  ? Icons.laptop_mac
                                  : Icons.trending_up,
                              size: 120,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 50),
                        Text(
                          onboardingData[index]["title"]!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                onboardingData.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  width: currentPage == index ? 30 : 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: currentPage == index
                        ? Colors.blue[700]
                        : Colors.grey[300],
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                children: [
                  if (currentPage < onboardingData.length - 1)
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeIn,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[700],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          "Selanjutnya",
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ),

                  if (currentPage == onboardingData.length - 1)
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => WelcomePage(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[700],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          "Mulai Sekarang",
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ),

                  const SizedBox(height: 15),

                  if (currentPage < onboardingData.length - 1)
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => WelcomePage(),
                          ),
                        );
                      },
                      child: Text(
                        "Lewat",
                        style: TextStyle(fontSize: 16, color: Colors.blue[700]),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
