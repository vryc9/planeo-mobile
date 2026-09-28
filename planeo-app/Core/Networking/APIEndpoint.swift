//
//  APIEndpoint.swift
//  planeo-app
//

import Foundation

enum APIEndpoint {
    case login(username: String, password: String)
    case balance
    case expenses
    case expenseMonth
    case expenseAmount
    case expensesByTags
    case createExpense(body: ExpenseCreateRequest)
    case updateBalance(amount: Double)

    var path: String {
        switch self {
        case .login:          return "/auth/login"   // pas de préfixe /api
        case .balance:        return "/api/balance"
        case .expenses:       return "/api/expense"
        case .expenseMonth:   return "/api/expense/month"
        case .expenseAmount:  return "/api/expense/amount"
        case .expensesByTags: return "/api/expense/tags"
        case .createExpense:  return "/api/expense"
        case .updateBalance:  return "/api/balance"
        }
    }

    var method: String {
        switch self {
        case .login, .createExpense: return "POST"
        case .updateBalance:         return "PUT"
        default:                     return "GET"
        }
    }

    var body: Encodable? {
        switch self {
        case .login(let u, let p):  return LoginRequest(username: u, password: p)
        case .createExpense(let b): return b
        case .updateBalance(let a): return a
        default:                    return nil
        }
    }
}

struct LoginRequest: Encodable {
    let username: String
    let password: String
}
