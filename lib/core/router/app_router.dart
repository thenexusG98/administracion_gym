import 'package:flutter/material.dart';
import 'package:valhalla_bjj/features/students/presentation/pages/students_page.dart';
import 'package:valhalla_bjj/features/students/presentation/pages/student_form_page.dart';
import 'package:valhalla_bjj/features/students/presentation/pages/student_detail_page.dart';
import 'package:valhalla_bjj/features/income/presentation/pages/income_page.dart';
import 'package:valhalla_bjj/features/income/presentation/pages/income_form_page.dart';
import 'package:valhalla_bjj/features/expenses/presentation/pages/expenses_page.dart';
import 'package:valhalla_bjj/features/expenses/presentation/pages/expense_form_page.dart';
import 'package:valhalla_bjj/features/inventory/presentation/pages/inventory_page.dart';
import 'package:valhalla_bjj/features/inventory/presentation/pages/product_form_page.dart';
import 'package:valhalla_bjj/features/inventory/presentation/pages/sell_product_page.dart';
import 'package:valhalla_bjj/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:valhalla_bjj/features/shell/presentation/pages/shell_page.dart';

class AppRouter {
  AppRouter._();

  // Rutas
  static const String shell = '/';
  static const String dashboard = '/dashboard';
  static const String students = '/students';
  static const String studentForm = '/students/form';
  static const String studentDetail = '/students/detail';
  static const String income = '/income';
  static const String incomeForm = '/income/form';
  static const String expenses = '/expenses';
  static const String expenseForm = '/expenses/form';
  static const String inventory = '/inventory';
  static const String productForm = '/inventory/form';
  static const String sellProduct = '/inventory/sell';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case shell:
        return _buildRoute(const ShellPage(), settings);
      case dashboard:
        return _buildRoute(const DashboardPage(), settings);
      case students:
        return _buildRoute(const StudentsPage(), settings);
      case studentForm:
        final studentId = settings.arguments as String?;
        return _buildRoute(StudentFormPage(studentId: studentId), settings);
      case studentDetail:
        final studentId = settings.arguments as String;
        return _buildRoute(StudentDetailPage(studentId: studentId), settings);
      case income:
        return _buildRoute(const IncomePage(), settings);
      case incomeForm:
        final incomeId = settings.arguments as String?;
        return _buildRoute(IncomeFormPage(incomeId: incomeId), settings);
      case expenses:
        return _buildRoute(const ExpensesPage(), settings);
      case expenseForm:
        final expenseId = settings.arguments as String?;
        return _buildRoute(ExpenseFormPage(expenseId: expenseId), settings);
      case inventory:
        return _buildRoute(const InventoryPage(), settings);
      case productForm:
        final productId = settings.arguments as String?;
        return _buildRoute(ProductFormPage(productId: productId), settings);
      case sellProduct:
        final productId = settings.arguments as String;
        return _buildRoute(SellProductPage(productId: productId), settings);
      default:
        return _buildRoute(const ShellPage(), settings);
    }
  }

  static MaterialPageRoute _buildRoute(Widget page, RouteSettings settings) {
    return MaterialPageRoute(
      builder: (_) => page,
      settings: settings,
    );
  }
}
