import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// Document Preview Screen
class DocumentPreviewScreen extends StatefulWidget {
  const DocumentPreviewScreen({super.key});

  @override
  State<DocumentPreviewScreen> createState() => _DocumentPreviewScreenState();
}

class _DocumentPreviewScreenState extends State<DocumentPreviewScreen> {
  bool isAccepted = false;
  bool isRejected = false;

  void _handleAccept() {
    setState(() {
      isAccepted = true;
      isRejected = false;
    });
  }

  void _handleReject() {
    setState(() {
      isAccepted = false;
      isRejected = true;
    });
  }

  void _handleDownload() {
    if (isAccepted) {
      // Show download confirmation or perform download
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(
              'Download Started',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              'The document is being downloaded.',
              style: TextStyle(fontSize: 14.sp),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(
                  'OK',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F0), // Light grey background
      body: SafeArea(
        child: Column(
          children: [
            // Top Download Button
            Padding(
              padding: EdgeInsets.only(top: 16.h, right: 16.w, left: 16.w),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isAccepted ? _handleDownload : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isAccepted 
                        ? const Color(0xFF4CAF50) // Green when enabled
                        : const Color(0xFFCCCCCC), // Grey when disabled
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'DOWNLOAD',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Icon(
                        Icons.download,
                        size: 20.sp,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SizedBox(height: 8.h),

            // Document Content Area
            Expanded(
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Document Title Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '০ এস সি আর',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: const Color(0xFF666666),
                            ),
                          ),
                          Text(
                            'সুপ্রিম কোর্ট রিপোর্ট',
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF333333),
                            ),
                          ),
                          Text(
                            '৫১০',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: const Color(0xFF666666),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 24.h),

                      // Document Content (Bengali Text)
                      Text(
                        'মোহাম্মদ নুরুল্লা, মরহুম খান সাহেবের এস্টেটের প্রতিনিধিত্ব করছেন মো. ওমর সাহৰ',
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: const Color(0xFF333333),
                          height: 1.6,
                        ),
                      ),

                      SizedBox(height: 16.h),

                      Text(
                        'আয়কর কমিশনার, মাহাস।',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF333333),
                          height: 1.6,
                        ),
                      ),

                      SizedBox(height: 16.h),

                      Text(
                        'বিচারপতিগণ জে. এল. কাপুর, এম. হেদায়াতুল্লাহ এবং জে. সি. শাহ,',
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: const Color(0xFF333333),
                          height: 1.6,
                        ),
                      ),

                      SizedBox(height: 16.h),

                      Text(
                        'একটি ব্যবসা, একজন ব্যক্তি যিনি ১৯৪২ সালে মারা যান, সম্পত্তির বিভাজন, ১৯৪০ সালে নিযুক্ত একজন রিসিভার এবং আয়কর মূল্যায়ন সম্পর্কে আলোচনা করা হচ্ছে।',
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: const Color(0xFF333333),
                          height: 1.6,
                        ),
                      ),

                      SizedBox(height: 16.h),

                      Text(
                        'এই নথিতে বিস্তারিত আইনি তথ্য এবং আয়কর কমিশনার এবং মৃত খান সাহেবের এস্টেটের মধ্যে মামলার বিবরণ অন্তর্ভুক্ত রয়েছে।',
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: const Color(0xFF333333),
                          height: 1.6,
                        ),
                      ),

                      SizedBox(height: 24.h),

                      // More document content
                      Text(
                        'মামলার পটভূমি:',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF333333),
                          height: 1.6,
                        ),
                      ),

                      SizedBox(height: 8.h),

                      Text(
                        'এই মামলাটি আয়কর মূল্যায়ন এবং সম্পত্তি বিভাজন সংক্রান্ত একটি গুরুত্বপূর্ণ আইনি বিতর্ক উপস্থাপন করে। মৃত খান সাহেবের এস্টেট এবং আয়কর কর্তৃপক্ষের মধ্যে বিরোধের মূল বিষয়গুলো নথিতে বিশদভাবে আলোচনা করা হয়েছে।',
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: const Color(0xFF333333),
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SizedBox(height: 8.h),

            // Accept/Reject Buttons
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Accept Button
                  GestureDetector(
                    onTap: _handleAccept,
                    child: Container(
                      width: 100.w,
                      height: 60.h,
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                      decoration: BoxDecoration(
                        color: isAccepted 
                            ? Colors.black 
                            : const Color(0xFFE0E0E0),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: Colors.black,
                          width: 2.w,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 18.w,
                            height: 18.w,
                            decoration: BoxDecoration(
                              color: isAccepted 
                                  ? Colors.white 
                                  : Colors.transparent,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.black,
                                width: 1.5.w,
                              ),
                            ),
                            child: isAccepted
                                ? Icon(
                                    Icons.check,
                                    size: 12.sp,
                                    color: Colors.black,
                                  )
                                : null,
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            'Accept',
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.bold,
                              color: isAccepted 
                                  ? Colors.white 
                                  : Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Reject Button
                  GestureDetector(
                    onTap: _handleReject,
                    child: Container(
                      width: 100.w,
                      height: 60.h,
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                      decoration: BoxDecoration(
                        color: isRejected 
                            ? Colors.black 
                            : const Color(0xFFE0E0E0),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: Colors.black,
                          width: 2.w,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 18.w,
                            height: 18.w,
                            decoration: BoxDecoration(
                              color: isRejected 
                                  ? Colors.white 
                                  : Colors.transparent,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.black,
                                width: 1.5.w,
                              ),
                            ),
                            child: isRejected
                                ? Icon(
                                    Icons.close,
                                    size: 12.sp,
                                    color: Colors.black,
                                  )
                                : null,
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            'Reject',
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.bold,
                              color: isRejected 
                                  ? Colors.white 
                                  : Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

