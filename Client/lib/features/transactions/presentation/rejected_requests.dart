import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kyrotics/services/webrtcController.dart';
import 'package:kyrotics/services/api_service.dart';
import 'package:kyrotics/models/transaction_model.dart';

class RejectedRequestsScreen extends ConsumerStatefulWidget {
  const RejectedRequestsScreen({super.key});

  @override
  ConsumerState<RejectedRequestsScreen> createState() => _RejectedRequestsScreenState();
}

class _RejectedRequestsScreenState extends ConsumerState<RejectedRequestsScreen> {
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
        type: 'sent',
        status: 'rejected',
      );
      setState(() {
        _transactions = transactions;
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
    // Group transactions by requestee (receiver)
    final groupedByRequestee = <String, List<DocumentTransaction>>{};
    for (var transaction in _transactions) {
      final key = transaction.receiverUuid;
      groupedByRequestee.putIfAbsent(key, () => []).add(transaction);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rejected Requests'),
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
              : groupedByRequestee.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.cancel_outlined,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            'No rejected requests',
                            style: TextStyle(fontSize: 18.sp, color: Colors.grey),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'Requests that were rejected will appear here',
                            style: TextStyle(fontSize: 14.sp, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadTransactions,
                      child: ListView.builder(
                        padding: EdgeInsets.all(16.w),
                        itemCount: groupedByRequestee.length,
                        itemBuilder: (context, index) {
                          final requesteeUuid = groupedByRequestee.keys.elementAt(index);
                          final transactions = groupedByRequestee[requesteeUuid]!;
                          final firstTransaction = transactions.first;

                          return Card(
                            margin: EdgeInsets.only(bottom: 16.h),
                            elevation: 2,
                            color: Colors.red.shade50,
                            child: ExpansionTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.red.shade300,
                                child: Text(
                                  firstTransaction.receiverName[0].toUpperCase(),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Text(
                                firstTransaction.receiverName,
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                '${transactions.length} rejected request(s)',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: Colors.red.shade700,
                                ),
                              ),
                              children: transactions.map((transaction) {
                                return ListTile(
                                  leading: const Icon(
                                    Icons.cancel,
                                    color: Colors.red,
                                  ),
                                  title: Text(
                                    'Requested on ${_formatDate(transaction.requestedAt)}',
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
                                      if (transaction.respondedAt != null)
                                        Padding(
                                          padding: EdgeInsets.only(top: 4.h),
                                          child: Text(
                                            'Rejected on ${_formatDate(transaction.respondedAt!)}',
                                            style: TextStyle(
                                              fontSize: 11.sp,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ),
                                      if (transaction.note != null &&
                                          transaction.note!.isNotEmpty)
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
                                    ],
                                  ),
                                  trailing: const Icon(
                                    Icons.arrow_forward_ios,
                                    size: 16,
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

