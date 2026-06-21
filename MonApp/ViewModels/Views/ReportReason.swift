//
//  ReportReason.swift
//  MonApp
//
//  Created by Thierno Moustapha BARRY  on 20/06/2026.
//

import Foundation

enum ReportReason: String, CaseIterable, Identifiable {

    case harassment = "Harcèlement ou intimidation"
    case insults = "Insultes ou discours haineux"
    case nudity = "Nudité ou contenu sexuel"
    case violence = "Violence ou menace"
    case scam = "Arnaque ou fraude"
    case spam = "Spam"
    case drugs = "Drogue"
    case weapon = "Arme dangereuse"
    case childSafety = "Danger pour mineur"
    case kidnapping = "Enlèvement ou séquestration"
    case terrorism = "Terrorisme ou extrémisme"
    case selfHarm = "Incitation à l'automutilation"
    case fakeIdentity = "Usurpation d'identité"
    case blackmail = "Chantage"
    case personalData = "Divulgation d'informations privées"
    case illegalActivity = "Activité illégale"
    case animalAbuse = "Maltraitance animale"
    case discrimination = "Discrimination"
    case misinformation = "Fausse information"
    case other = "Autre"

    var id: String { rawValue }
}
