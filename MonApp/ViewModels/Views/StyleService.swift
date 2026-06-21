//
//  StyleService.swift
//  MonApp
//
//  Created by Thierno Moustapha BARRY  on 20/06/2026.
//

import Foundation
import FirebaseFirestore

final class StyleService {

    static let shared = StyleService()

    private let db = Firestore.firestore()

    func loadStyles(
        completion: @escaping ([Style]) -> Void
    ) {

        db.collection("styles")
            .order(by: "createdAt", descending: true)
            .getDocuments { snapshot, error in

                guard let docs = snapshot?.documents else {
                    completion([])
                    return
                }

                let styles = docs.compactMap {
                    try? $0.data(as: Style.self)
                }

                completion(styles)
            }
    }
}
