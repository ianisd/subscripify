import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import '../models/subscription.dart';
import '../services/notification_service.dart';

class AddSubscriptionScreen extends StatefulWidget {
  final Subscription? subscription; // If provided, we are in Edit Mode

  const AddSubscriptionScreen({super.key, this.subscription});

  @override
  State<AddSubscriptionScreen> createState() => _AddSubscriptionScreenState();
}

class _AddSubscriptionScreenState extends State<AddSubscriptionScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _amountController;
  late DateTime _selectedDate;
  late String _period;
  late String _category;

  final List<String> _categories = ['Entertainment', 'Utilities', 'Work', 'Personal', 'Health', 'Other'];

  @override
  void initState() {
    super.initState();
    // Pre-fill data if editing, otherwise defaults
    _nameController = TextEditingController(text: widget.subscription?.name ?? '');
    _amountController = TextEditingController(text: widget.subscription?.amount.toString() ?? '');
    _selectedDate = widget.subscription?.nextBillDate ?? DateTime.now();
    _period = widget.subscription?.period ?? "Monthly";
    _category = widget.subscription?.category ?? "Entertainment";
  }

  void _saveSubscription() async {
    if (_formKey.currentState!.validate()) {
      final box = Hive.box<Subscription>('subscriptions');
      final double amount = double.parse(_amountController.text);

      int notifId;

      if (widget.subscription != null) {
        // --- EDIT MODE ---
        // 1. Get the existing stable ID
        notifId = widget.subscription!.notificationId;

        // 2. CANCEL the existing notification for this ID
        // (This ensures we don't have a "ghost" alert for the old date)
        await NotificationService.cancelNotification(notifId);

        // 3. Update Hive Data
        widget.subscription!.name = _nameController.text;
        widget.subscription!.amount = amount;
        widget.subscription!.nextBillDate = _selectedDate;
        widget.subscription!.period = _period;
        widget.subscription!.category = _category;

        await widget.subscription!.save();

      } else {
        // --- CREATE MODE ---
        // 1. Create Object (Constructor generates the random ID)
        final newSub = Subscription(
          name: _nameController.text,
          amount: amount,
          nextBillDate: _selectedDate,
          period: _period,
          category: _category,
        );

        // 2. Save to Hive
        await box.add(newSub);

        // 3. Grab the ID for scheduling
        notifId = newSub.notificationId;
      }

      // --- SCHEDULE NEW ---
      // Regardless of Edit or Create, we schedule the new date with the stable ID
      await NotificationService.scheduleNotification(
        notifId,
        _nameController.text,
        _selectedDate,
      );

      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.subscription == null ? "New Subscription" : "Edit Subscription")),
      body: SingleChildScrollView( // Added scroll for small screens
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Service Name", border: OutlineInputBorder()),
                validator: (val) => val!.isEmpty ? "Enter a name" : null,
              ),
              const SizedBox(height: 15),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "Amount", border: OutlineInputBorder()),
                      validator: (val) => val!.isEmpty ? "Enter amount" : null,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _period,
                      decoration: const InputDecoration(labelText: "Cycle", border: OutlineInputBorder()),
                      items: ["Monthly", "Yearly", "Weekly"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (val) => setState(() => _period = val!),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(labelText: "Category", border: OutlineInputBorder()),
                items: _categories.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (val) => setState(() => _category = val!),
              ),

              const SizedBox(height: 20),
              const Text("Next Billing Date:", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) setState(() => _selectedDate = picked);
                },
                child: Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 20),
                      const SizedBox(width: 10),
                      Text(DateFormat('MMMM d, y').format(_selectedDate)),
                    ],
                  ),
                ),
              ),

          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                // FORCE INDIGO COLOR (Ignored Dark Mode Theme)
                backgroundColor: Colors.indigo,
                // FORCE WHITE TEXT
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _saveSubscription,
              child: Text(
                widget.subscription == null ? "Save Subscription" : "Update Subscription",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
            ],
          ),
        ),
      ),
    );
  }
}