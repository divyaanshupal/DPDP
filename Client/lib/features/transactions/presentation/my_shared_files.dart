import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kyrotics/services/webrtcController.dart';
import 'package:kyrotics/services/api_service.dart';
import 'package:kyrotics/models/transaction_model.dart';

class MySharedFilesScreen extends ConsumerStatefulWidget {
  const MySharedFilesScreen({super.key});

  @override
  ConsumerState<MySharedFilesScreen> createState() => _MySharedFilesScreenState();
}

class _MySharedFilesScreenState extends ConsumerState<MySharedFilesScreen> {
  List<DocumentTransaction> _transactions = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    final uuid = ref.read(webrtcProvider).selfUuid;
    if (uuid == null) {
      setState(() {
        _isLoading = false;
        _error = 'User UUID not found';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final transactions = await ref.read(apiServiceProvider).getTransactions(
        uuid: uuid,
        type: 'received',
      );
      // Filter for accepted/completed transactions only
      final filteredTransactions = transactions
          .where((t) => t.status != 'rejected' )
          .toList();
      setState(() {
        _transactions = filteredTransactions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    // Group transactions by sender (the person you shared files with)
    final groupedBySender = <String, List<DocumentTransaction>>{};
    for (var transaction in _transactions) {
      final key = transaction.senderUuid;
      groupedBySender.putIfAbsent(key, () => []).add(transaction);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Shared Files'),
        backgroundColor: const Color(0xFF5170FF),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTransactions,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red),
                      SizedBox(height: 16.h),
                      Text(
                        'Error loading transactions',
                        style: TextStyle(fontSize: 18.sp, color: Colors.grey),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        _error!,
                        style: TextStyle(fontSize: 14.sp, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 20.h),
                      ElevatedButton(
                        onPressed: _loadTransactions,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : groupedBySender.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.share_outlined,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            'No shared files yet',
                            style: TextStyle(fontSize: 18.sp, color: Colors.grey),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'Files you share with others will appear here',
                            style: TextStyle(fontSize: 14.sp, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadTransactions,
                      child: ListView.builder(
                        padding: EdgeInsets.all(16.w),
                        itemCount: groupedBySender.length,
                        itemBuilder: (context, index) {
                          final senderUuid = groupedBySender.keys.elementAt(index);
                          final transactions = groupedBySender[senderUuid]!;
                          final firstTransaction = transactions.first;

                          return Card(
                            margin: EdgeInsets.only(bottom: 16.h),
                            elevation: 2,
                            child: ExpansionTile(
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFF5170FF),
                                child: Text(
                                  firstTransaction.senderName[0].toUpperCase(),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Text(
                                firstTransaction.senderName,
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                '${transactions.length} transaction(s)',
                                style: TextStyle(fontSize: 14.sp, color: Colors.grey),
                              ),
                              children: transactions.map((transaction) {
                                final viewOnlyCount = transaction.requestedDocuments
                                    .where((d) => d.requestType == 'view')
                                    .length;
                                final downloadCount = transaction.requestedDocuments
                                    .where((d) => d.requestType == 'download')
                                    .length;

                                return ListTile(
                                  leading: Icon(
                                    transaction.status == 'completed'
                                        ? Icons.check_circle
                                        : Icons.pending,
                                    color: transaction.status == 'completed'
                                        ? Colors.green
                                        : Colors.orange,
                                  ),
                                  title: Text(
                                    'Sent on ${_formatDate(transaction.requestedAt)}',
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(height: 4.h),
                                      Text(
                                        'Documents: ${transaction.requestedDocuments.map((d) => d.name).join(", ")}',
                                        style: TextStyle(fontSize: 12.sp),
                                      ),
                                      SizedBox(height: 4.h),
                                      Row(
                                        children: [
                                          if (viewOnlyCount > 0)
                                            Row(
                                              children: [
                                                Icon(Icons.visibility,
                                                    size: 12.sp, color: Colors.blue),
                                                SizedBox(width: 4.w),
                                                Text('$viewOnlyCount View Only',
                                                    style: TextStyle(fontSize: 11.sp)),
                                              ],
                                            ),
                                          if (viewOnlyCount > 0 && downloadCount > 0)
                                            SizedBox(width: 12.w),
                                          if (downloadCount > 0)
                                            Row(
                                              children: [
                                                Icon(Icons.download,
                                                    size: 12.sp, color: Colors.green),
                                                SizedBox(width: 4.w),
                                                Text('$downloadCount Downloadable',
                                                    style: TextStyle(fontSize: 11.sp)),
                                              ],
                                            ),
                                        ],
                                      ),
                                      if (transaction.note != null && transaction.note!.isNotEmpty)
                                        Padding(
                                          padding: EdgeInsets.only(top: 4.h),
                                          child: Text(
                                            'Note: ${transaction.note}',
                                            style: TextStyle(
                                              fontSize: 11.sp,
                                              fontStyle: FontStyle.italic,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ),
                                      SizedBox(height: 4.h),
                                      // Text(
                                      //   'Status: ${transaction.status.toUpperCase()}',
                                      //   style: TextStyle(
                                      //     fontSize: 11.sp,
                                      //     fontWeight: FontWeight.bold,
                                      //     color: transaction.status == 'completed'
                                      //         ? Colors.green
                                      //         : Colors.orange,
                                      //   ),
                                      // ),
                                    ],
                                  ),
                                  trailing: Icon(
                                    Icons.arrow_forward_ios,
                                    size: 16.sp,
                                  ),
                                );
                              }).toList(),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}

