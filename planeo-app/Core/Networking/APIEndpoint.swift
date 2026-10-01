//
//  APIEndpoint.swift
//  planeo-app
//

import Foundation

enum APIEndpoint {
    case login(username: String, password: String)
    case reauth(password: String)
    case deleteAccount
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

    /// Un 401 sur ces endpoints = mauvais mot de passe, pas une session expirée.
    var isCredentialCheck: Bool {
        switch self {
        case .login, .reauth: return true
        default:              return false
        }
    }

    var path: String {
        switch self {
        case .login:                   return "/auth/login"   // pas de préfixe /api
        case .reauth:                  return "/auth/reauth"
        case .deleteAccount:           return "/api/me/account"
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
        case .login, .reauth, .createExpense, .createAccounts, .transfer, .createCategory: return "POST"
        case .deposit:                                                            return "PUT"
        case .deleteExpense, .deleteCategory, .deleteAccount:                     return "DELETE"
        default:                                                                  return "GET"
        }
    }

    var body: Encodable? {
        switch self {
        case .login(let u, let p):    return LoginRequest(username: u, password: p)
        case .reauth(let p):          return ReauthRequest(password: p)
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

struct ReauthRequest: Encodable {
    let password: String
}
