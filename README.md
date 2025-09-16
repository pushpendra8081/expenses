
---

I want you to generate a complete Flutter project for an Expense Management App with the following specifications:

**State Management:** Riverpod
**Database:** Hive

**Features:**

1. **Expense Entry Form:** Users can add expenses with amount, category, date, optional notes, and optional merchant.

2. **Local Database Integration:**

* Use Hive to store expenses locally.
* Support add, edit, delete, and view expenses.

3. **OCR Integration:**

* Integrate Google ML Kit OCR.
* User can scan a receipt and extract amount, date, and merchant name.
* The extracted fields should appear in the add-expense form editable by the user before saving.

4. **AI-powered Category Suggestions:**

* Use a rule-based system: suggest categories based on merchant or notes keywords (e.g., "uber" → "Transport", "amazon" → "Shopping").

5. **Location Access:**

* Capture user location when adding an expense using geolocator.
* Save coordinates with the expense.
* Optionally display location on a map using flutter\_map or google\_maps\_flutter.

6. **Expense Summary:**

* Show total expenses by category.
* Support filtering by date range.
* Display totals in a list or chart (bar chart or pie chart).

**UI/UX:**

* Simple, clean, and responsive.
* Editable OCR results before saving.
* Snackbars/toasts on add, edit, delete.
* Confirm delete with a dialog.

**Project Structure Suggestion:**

```
lib/
  main.dart
  src/
    models/
      expense.dart
    db/
      hive_service.dart
    providers/
      expense_provider.dart
    screens/
      home_screen.dart
      add_edit_expense.dart
      receipt_scan_screen.dart
      summary_screen.dart
      map_view_screen.dart
    widgets/
      expense_tile.dart
      chart_widget.dart
    services/
      ocr_service.dart
      suggestion_service.dart
      location_service.dart
    utils/
      date_utils.dart
      currency_utils.dart
assets/
```

**Other Requirements:**

* Use proper Riverpod providers for state management.
* Hive should store the data efficiently; include a Hive adapter for the Expense model.
* Ensure proper permissions handling for camera and location.
