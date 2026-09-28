//
//  APIEndpoint.swift
//  planeo-app
//

import Foundation

enum APIEndpoint {
    case login(username: String, password: String)
    case balance
    case deposit(body: DepositRequest)
    case expenses
    case expenseMonth
    case expenseAmountByCategory
    case createExpense(body: ExpenseCreateRequest)
    case deleteExpense(body: ExpenseDTO)
    case accounts
    case accountsExist
    case createAccounts(body: [AccountCreateRequest])
    case transfer(body: TransferRequest)
    case categories
    case createCategory(body: CategoryCreateRequest)
    case deleteCategory(body: CategoryDTO)

    var isLogin: Bool {
        if case .login = self { return true }
        return false
    }

    var path: String {
        switch self {
        case .login:                   return "/auth/login"   // pas de préfixe /api
        case .balance, .deposit:       return "/api/balance"
        case .expenses, .createExpense, .deleteExpense: return "/api/expense"
        case .expenseMonth:            return "/api/expense/month"
        case .expenseAmountByCategory: return "/api/expense/amount/category"
        case .accounts, .createAccounts: return "/api/accounts"
        case .accountsExist:           return "/api/accounts/exist"
        case .transfer:                return "/api/accounts/transfert"
        case .categories, .createCategory, .deleteCategory: return "/api/category"
        }
    }

    var method: String {
        switch self {
        case .login, .createExpense, .createAccounts, .transfer, .createCategory: return "POST"
        case .deposit:                                                            return "PUT"
        case .deleteExpense, .deleteCategory:                                     return "DELETE"
        default:                                                                  return "GET"
        }
    }

    var body: Encodable? {
        switch self {
        case .login(let u, let p):    return LoginRequest(username: u, password: p)
        case .deposit(let b):         return b
        case .createExpense(let b):   return b
        case .deleteExpense(let b):   return b
        case .createAccounts(let b):  return b
        case .transfer(let b):        return b
        case .createCategory(let b):  return b
        case .deleteCategory(let b):  return b
        default:                      return nil
        }
    }
}

struct LoginRequest: Encodable {
    let username: String
    let password: String
}
