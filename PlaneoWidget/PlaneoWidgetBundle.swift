// xcode: set sdk=iOS

//
//  PlaneoWidgetBundle.swift
//  PlaneoWidgetExtension
//
//  Point d'entrée du widget (@main — UN seul par target).
//

import WidgetKit
import SwiftUI

@main struct PlaneoWidgetBundle: WidgetBundle {
    var body: some Widget {
        PlaneoWidget()
    }
}
