//
//  MarketplaceLegalPrivacyView.swift
//  MonApp
//
//  Created by Thierno Moustapha BARRY  on 30/06/2026.
//

import SwiftUI

struct MarketplaceLegalPrivacyView: View {

    @Environment(\.colorScheme) private var colorScheme

    @State private var animateHeader = false
    @State private var selectedLanguage = MarketplaceLegalLanguage.system

    var body: some View {
        NavigationStack {
            ZStack {

                MarketplaceUITheme.softBackgroundGradient
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {

                    VStack(spacing: 22) {

                        heroSection
                        languageSection
                        summarySection
                        legalContentSection
                        Spacer(minLength: 120)
                    }
                    .padding(.vertical,18)
                }
            }
            .navigationTitle("Politique & confidentialité")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
extension MarketplaceLegalPrivacyView {
    
    private var heroSection: some View {
        
        VStack(alignment: .leading, spacing: 18) {
            
            HStack {
                
                VStack(alignment: .leading, spacing: 8) {
                    
                    Text("Politique & confidentialité")
                        .font(.system(size:30,weight:.black,design:.rounded))
                        .foregroundStyle(.white)
                    
                    Text("Protection des données, paiements, Marketplace, IA, certification, vendeurs, acheteurs et sécurité.")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.82))
                }
                
                Spacer()
                
                MarketplaceIconBadge(
                    icon: "lock.shield.fill",
                    size: 64
                )
            }
            
            HStack(spacing:10){
                
                MarketplaceLegalChip(
                    title: "RGPD",
                    icon: "lock.fill"
                )
                
                MarketplaceLegalChip(
                    title: "Marketplace",
                    icon: "cart.fill"
                )
                
                MarketplaceLegalChip(
                    title: "IA",
                    icon: "brain.head.profile"
                )
            }
        }
        .padding(22)
        .background(MarketplaceUITheme.darkLuxuryGradient)
        .clipShape(
            RoundedRectangle(
                cornerRadius: MarketplaceUITheme.cornerXL,
                style: .continuous
            )
        )
        .overlay(
            MarketplaceUITheme.premiumStroke(
                colorScheme: colorScheme,
                cornerRadius: MarketplaceUITheme.cornerXL
            )
        )
        .padding(.horizontal,16)
        .scaleEffect(animateHeader ? 1 : 0.97)
        .opacity(animateHeader ? 1 : 0)
        .onAppear{
            
            withAnimation(.spring(response:0.55,dampingFraction:0.82)){
                animateHeader = true
            }
            
        }
        
    }
    
    private var languageSection: some View {
        
        VStack(alignment:.leading,spacing:14){
            
            MarketplaceSectionHeader(
                title: "Langue",
                subtitle: "Lire les documents dans votre langue",
                actionTitle: nil,
                action: nil
            )
            .padding(.horizontal,0)
            
            Picker(
                "Langue",
                selection: $selectedLanguage
            ){
                
                ForEach(
                    MarketplaceLegalLanguage.allCases
                ){ language in
                    
                    Text(language.title)
                        .tag(language)
                    
                }
                
            }
            .pickerStyle(.menu)
            .padding(16)
            .background(.regularMaterial)
            .clipShape(
                RoundedRectangle(
                    cornerRadius:22,
                    style:.continuous
                )
            )
            
            Text("Les politiques seront progressivement disponibles dans toutes les langues prises en charge par Cutly.")
                .font(.caption)
                .foregroundStyle(.secondary)
            
        }
        .padding(18)
        .background(.regularMaterial)
        .clipShape(
            RoundedRectangle(
                cornerRadius:30,
                style:.continuous
            )
        )
        .padding(.horizontal,16)
        
    }
    
    private var summarySection: some View {
        
        VStack(alignment:.leading,spacing:14){
            
            MarketplaceSectionHeader(
                title: "Sommaire",
                subtitle: "Navigation rapide",
                actionTitle: nil,
                action: nil
            )
            .padding(.horizontal,0)
            
            MarketplaceLegalRow(icon:"person.fill",title:"1. Données personnelles")
            MarketplaceLegalRow(icon:"creditcard.fill",title:"2. Paiements")
            MarketplaceLegalRow(icon:"shippingbox.fill",title:"3. Livraison")
            MarketplaceLegalRow(icon:"cart.fill",title:"4. Marketplace")
            MarketplaceLegalRow(icon:"storefront.fill",title:"5. Boutiques")
            MarketplaceLegalRow(icon:"checkmark.seal.fill",title:"6. Certification")
            MarketplaceLegalRow(icon:"arrow.uturn.backward.circle.fill",title:"7. Retours & remboursements")
            MarketplaceLegalRow(icon:"exclamationmark.shield.fill",title:"8. Litiges")
            MarketplaceLegalRow(icon:"brain.head.profile",title:"9. Intelligence artificielle")
            MarketplaceLegalRow(icon:"lock.shield.fill",title:"10. Sécurité")
            MarketplaceLegalRow(icon:"doc.text.fill",title:"11. Conditions générales")
            MarketplaceLegalRow(icon:"globe",title:"12. Droit international")
            
        }
        .padding(18)
        .background(.regularMaterial)
        .clipShape(
            RoundedRectangle(
                cornerRadius:30,
                style:.continuous
            )
        )
        .padding(.horizontal,16)
        
    }
    private var legalContentSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            MarketplaceSectionHeader(
                title: selectedLanguage == .english ? "Legal content" : "Contenu juridique",
                subtitle: selectedLanguage == .english ? "Privacy, payments, sellers, buyers and platform rules" : "Confidentialité, paiements, vendeurs, acheteurs et règles plateforme",
                actionTitle: nil,
                action: nil
            )
            .padding(.horizontal, 0)

            MarketplaceLegalTextBlock(
                title: selectedLanguage == .english ? "1. Personal data" : "1. Données personnelles",
                text: selectedLanguage == .english
                ? "Cutly Marketplace may collect account information, contact details, country, language, delivery preferences, purchase activity, seller activity, payment status, support messages, dispute history and security signals. This data is used to operate the marketplace, protect users, process orders, improve recommendations, fight fraud and comply with legal obligations."
                : "Cutly Marketplace peut collecter les informations de compte, coordonnées, pays, langue, préférences de livraison, activité d’achat, activité de vente, statut des paiements, messages support, historique des litiges et signaux de sécurité. Ces données servent à faire fonctionner la marketplace, protéger les utilisateurs, traiter les commandes, améliorer les recommandations, lutter contre la fraude et respecter les obligations légales."
            )

            MarketplaceLegalTextBlock(
                title: selectedLanguage == .english ? "2. Payments and withdrawals" : "2. Paiements et retraits",
                text: selectedLanguage == .english
                ? "Payments may be processed through Stripe, Apple Pay, PayPal, bank cards, bank transfer, Mobile Money providers, Wallet Cutly or regional payment partners depending on the user’s country. Sellers may be required to complete identity verification before receiving payouts. Cutly may hold, review or delay payouts in cases of suspected fraud, disputes, abnormal refunds or legal requirements."
                : "Les paiements peuvent être traités via Stripe, Apple Pay, PayPal, cartes bancaires, virement, Mobile Money, Wallet Cutly ou partenaires régionaux selon le pays de l’utilisateur. Les vendeurs peuvent devoir effectuer une vérification d’identité avant de recevoir leurs retraits. Cutly peut retenir, vérifier ou retarder un retrait en cas de suspicion de fraude, litige, remboursement anormal ou obligation légale."
            )

            MarketplaceLegalTextBlock(
                title: selectedLanguage == .english ? "3. Marketplace sales" : "3. Ventes Marketplace",
                text: selectedLanguage == .english
                ? "Any user may buy and sell on Cutly Marketplace. Professional stores are optional and may provide additional tools, branding, analytics and certification. Sellers must provide accurate product information, real photos, correct prices, delivery conditions and must not sell prohibited, counterfeit, dangerous or illegal items."
                : "Tout utilisateur peut acheter et vendre sur Cutly Marketplace. Les boutiques professionnelles sont optionnelles et peuvent proposer des outils supplémentaires, une identité visuelle, des statistiques et une certification. Les vendeurs doivent fournir des informations exactes, de vraies photos, des prix corrects, des conditions de livraison claires et ne pas vendre de produits interdits, contrefaits, dangereux ou illégaux."
            )

            MarketplaceLegalTextBlock(
                title: selectedLanguage == .english ? "4. Returns, refunds and disputes" : "4. Retours, remboursements et litiges",
                text: selectedLanguage == .english
                ? "Buyers and sellers may open a return, refund or dispute request when an order is not delivered, damaged, different from the description, suspected counterfeit or affected by payment or delivery issues. Cutly may request photos, videos, tracking proof, signatures, messages and other evidence before making a decision."
                : "Acheteurs et vendeurs peuvent ouvrir une demande de retour, remboursement ou litige lorsqu’une commande n’est pas livrée, est endommagée, différente de la description, suspectée de contrefaçon ou concernée par un problème de paiement ou de livraison. Cutly peut demander photos, vidéos, preuve de suivi, signature, messages et autres éléments avant décision."
            )

            MarketplaceLegalTextBlock(
                title: selectedLanguage == .english ? "5. Artificial intelligence and safety" : "5. Intelligence artificielle et sécurité",
                text: selectedLanguage == .english
                ? "Cutly may use automated systems and AI tools to detect fake sellers, counterfeit products, stolen images, fake reviews, suspicious orders, abusive refunds, money laundering risks, spam, harassment and unsafe conversations. AI decisions may be reviewed manually when necessary."
                : "Cutly peut utiliser des systèmes automatisés et des outils d’IA pour détecter les faux vendeurs, contrefaçons, images volées, faux avis, commandes suspectes, remboursements abusifs, risques de blanchiment, spam, harcèlement et conversations dangereuses. Les décisions IA peuvent être revues manuellement si nécessaire."
            )
            MarketplaceLegalTextBlock(
                title: selectedLanguage == .english ? "6. Prohibited products and counterfeits" : "6. Produits interdits et contrefaçons",
                text: selectedLanguage == .english
                ? "Users must not sell counterfeit products, stolen goods, dangerous items, illegal items, weapons, restricted substances, fake documents or any product that violates applicable laws. Cutly may remove listings, suspend accounts, block payouts or report serious violations when required."
                : "Les utilisateurs ne doivent pas vendre de contrefaçons, produits volés, articles dangereux, produits illégaux, armes, substances réglementées, faux documents ou tout produit contraire aux lois applicables. Cutly peut supprimer une annonce, suspendre un compte, bloquer un retrait ou signaler une violation grave si nécessaire."
            )

            MarketplaceLegalTextBlock(
                title: selectedLanguage == .english ? "7. Certification and verified badges" : "7. Certification et badges vérifiés",
                text: selectedLanguage == .english
                ? "Cutly certification may be available for individuals, buyer-seller profiles, professional stores, brands and partners. Certification may require identity checks, store verification, payment review and compliance with marketplace rules. Certification can be paid and does not guarantee that every transaction will be risk-free."
                : "La certification Cutly peut être disponible pour les particuliers, profils acheteur-vendeur, boutiques professionnelles, marques et partenaires. Elle peut nécessiter une vérification d’identité, une vérification de boutique, un contrôle paiement et le respect des règles Marketplace. La certification peut être payante et ne garantit pas qu’une transaction sera toujours sans risque."
            )

            MarketplaceLegalTextBlock(
                title: selectedLanguage == .english ? "8. Reviews and community trust" : "8. Avis et confiance communautaire",
                text: selectedLanguage == .english
                ? "Reviews must reflect real experiences. Fake reviews, paid manipulation, intimidation, spam or coordinated rating abuse are prohibited. Cutly may analyze reviews with automated systems and may hide, remove or investigate suspicious reviews."
                : "Les avis doivent refléter une expérience réelle. Les faux avis, manipulations payées, intimidations, spam ou abus coordonnés de notation sont interdits. Cutly peut analyser les avis avec des systèmes automatisés et masquer, supprimer ou enquêter sur les avis suspects."
            )

            MarketplaceLegalTextBlock(
                title: selectedLanguage == .english ? "9. International delivery and local pickup" : "9. Livraison internationale et retrait local",
                text: selectedLanguage == .english
                ? "Delivery options may include home delivery, pickup points, post offices, local agencies, partner shops, local couriers, bus agencies, GPS location, landmarks and hand delivery. In some countries, phone number and local instructions may be required to complete delivery."
                : "Les options de livraison peuvent inclure la livraison à domicile, points relais, bureaux de poste, agences locales, commerçants partenaires, coursiers locaux, agences de bus, coordonnées GPS, points de repère et remise en main propre. Dans certains pays, le téléphone et des instructions locales peuvent être nécessaires."
            )

            MarketplaceLegalTextBlock(
                title: selectedLanguage == .english ? "10. Account suspension and enforcement" : "10. Suspension de compte et sanctions",
                text: selectedLanguage == .english
                ? "Cutly may limit, suspend or close accounts that violate marketplace rules, create risk for other users, attempt fraud, sell prohibited products, abuse refunds, manipulate reviews or avoid platform fees. Users may be asked to provide additional information before access is restored."
                : "Cutly peut limiter, suspendre ou fermer les comptes qui violent les règles Marketplace, créent un risque pour les autres utilisateurs, tentent une fraude, vendent des produits interdits, abusent des remboursements, manipulent les avis ou contournent les frais plateforme. Des informations supplémentaires peuvent être demandées avant rétablissement."
            )
            MarketplaceLegalTextBlock(
                title: selectedLanguage == .english ? "11. User rights and data deletion" : "11. Droits utilisateurs et suppression des données",
                text: selectedLanguage == .english
                ? "Users may request access, correction, export or deletion of their personal data where applicable. Some data may be retained when necessary for fraud prevention, legal obligations, payment records, disputes, accounting, security investigations or regulatory requirements."
                : "Les utilisateurs peuvent demander l’accès, la correction, l’export ou la suppression de leurs données personnelles lorsque cela est applicable. Certaines données peuvent être conservées si nécessaire pour la prévention de la fraude, obligations légales, paiements, litiges, comptabilité, enquêtes de sécurité ou exigences réglementaires."
            )

            MarketplaceLegalTextBlock(
                title: selectedLanguage == .english ? "12. Children and minors" : "12. Mineurs et protection des jeunes",
                text: selectedLanguage == .english
                ? "Cutly Marketplace is intended for users who meet the legal age required in their country to buy, sell or enter into transactions. Minors may need parental or legal guardian consent. Cutly may restrict access when age, safety or legal concerns are identified."
                : "Cutly Marketplace est destinée aux utilisateurs ayant l’âge légal requis dans leur pays pour acheter, vendre ou conclure des transactions. Les mineurs peuvent avoir besoin de l’accord d’un parent ou représentant légal. Cutly peut restreindre l’accès en cas de problème d’âge, de sécurité ou d’obligation légale."
            )

            MarketplaceLegalTextBlock(
                title: selectedLanguage == .english ? "13. Intellectual property" : "13. Propriété intellectuelle",
                text: selectedLanguage == .english
                ? "Users must respect trademarks, copyrights, images, logos, designs and third-party rights. Sellers must not use stolen photos, protected brand names or misleading descriptions. Rights holders may contact Cutly to report infringement or counterfeit products."
                : "Les utilisateurs doivent respecter les marques, droits d’auteur, images, logos, designs et droits de tiers. Les vendeurs ne doivent pas utiliser de photos volées, noms de marques protégés ou descriptions trompeuses. Les ayants droit peuvent contacter Cutly pour signaler une atteinte ou une contrefaçon."
            )

            MarketplaceLegalTextBlock(
                title: selectedLanguage == .english ? "14. Platform fees and commissions" : "14. Frais plateforme et commissions",
                text: selectedLanguage == .english
                ? "Cutly may charge service fees, marketplace commissions, payment processing fees, withdrawal fees, promotion fees or certification fees. Fees may vary depending on country, currency, payment method, seller status, store type, promotions or applicable taxes."
                : "Cutly peut facturer des frais de service, commissions marketplace, frais de paiement, frais de retrait, frais de promotion ou frais de certification. Les frais peuvent varier selon le pays, la devise, le moyen de paiement, le statut vendeur, le type de boutique, les promotions ou taxes applicables."
            )

            MarketplaceLegalTextBlock(
                title: selectedLanguage == .english ? "15. Changes to these terms" : "15. Modification des conditions",
                text: selectedLanguage == .english
                ? "Cutly may update these policies to reflect product changes, legal requirements, security needs or marketplace evolution. Users may be notified when important changes are made. Continued use of the marketplace may mean acceptance of updated terms."
                : "Cutly peut mettre à jour ces politiques pour refléter les évolutions du produit, obligations légales, besoins de sécurité ou changements de la marketplace. Les utilisateurs peuvent être informés en cas de modification importante. L’utilisation continue de la marketplace peut valoir acceptation des nouvelles conditions."
            )
            
            MarketplaceLegalTextBlock(
                title: selectedLanguage == .english ? "16. Platform responsibility" : "16. Responsabilité de la plateforme",
                text: selectedLanguage == .english
                ? "Cutly provides tools that connect buyers, sellers, stores, payment providers and delivery partners. Cutly may help manage disputes, payments, fraud signals and support, but sellers remain responsible for the accuracy of their listings, products, prices, availability and delivery commitments."
                : "Cutly fournit des outils qui mettent en relation acheteurs, vendeurs, boutiques, prestataires de paiement et partenaires de livraison. Cutly peut aider à gérer les litiges, paiements, signaux de fraude et support, mais les vendeurs restent responsables de l’exactitude de leurs annonces, produits, prix, disponibilité et engagements de livraison."
            )

            MarketplaceLegalTextBlock(
                title: selectedLanguage == .english ? "17. Taxes and legal obligations" : "17. Taxes et obligations légales",
                text: selectedLanguage == .english
                ? "Users, sellers and professional stores are responsible for understanding and respecting tax, customs, import, export and business registration obligations applicable in their country. Cutly may provide transaction history, invoices or reports when technically available."
                : "Les utilisateurs, vendeurs et boutiques professionnelles sont responsables de comprendre et respecter les obligations fiscales, douanières, d’importation, d’exportation et d’enregistrement d’entreprise applicables dans leur pays. Cutly peut fournir un historique, des factures ou rapports lorsque cela est techniquement disponible."
            )

            MarketplaceLegalTextBlock(
                title: selectedLanguage == .english ? "18. Evidence and records" : "18. Preuves et historiques",
                text: selectedLanguage == .english
                ? "Cutly may keep records of orders, payments, messages, tracking events, delivery proofs, signatures, refund requests and dispute evidence to protect users, investigate incidents, prevent fraud and comply with legal obligations."
                : "Cutly peut conserver les historiques de commandes, paiements, messages, suivis colis, preuves de livraison, signatures, demandes de remboursement et preuves de litige afin de protéger les utilisateurs, enquêter sur les incidents, prévenir la fraude et respecter les obligations légales."
            )

            MarketplaceLegalTextBlock(
                title: selectedLanguage == .english ? "19. Contact and support" : "19. Contact et support",
                text: selectedLanguage == .english
                ? "Users may contact Cutly support for questions about orders, payments, delivery, disputes, certification, privacy, data deletion or security. Dedicated support channels may vary depending on country, language, account type and urgency."
                : "Les utilisateurs peuvent contacter le support Cutly pour toute question concernant les commandes, paiements, livraison, litiges, certification, confidentialité, suppression des données ou sécurité. Les canaux de support peuvent varier selon le pays, la langue, le type de compte et l’urgence."
            )

            MarketplaceLegalTextBlock(
                title: selectedLanguage == .english ? "20. Important legal notice" : "20. Note juridique importante",
                text: selectedLanguage == .english
                ? "This document is a product draft and must be reviewed by a qualified legal professional before official publication. Laws may vary by country, especially for payments, consumer protection, data privacy, taxes, delivery, imports and marketplace liability."
                : "Ce document est une base produit et doit être relu par un professionnel du droit avant publication officielle. Les lois peuvent varier selon les pays, notamment pour les paiements, la protection des consommateurs, les données personnelles, taxes, livraison, importations et responsabilité marketplace."
            )
            
            
            Text("⚠️ Ce texte est une base de travail produit. Il faudra le faire valider par un juriste avant publication officielle.")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
                .padding(.top, 8)
        }
        .padding(18)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .padding(.horizontal, 16)
    }
    
    
    
    
}
enum MarketplaceLegalLanguage: String, CaseIterable, Identifiable {

    case system
    case french
    case english

    var id: String { rawValue }

    var title: String {

        switch self {

        case .system:
            return "Automatique"

        case .french:
            return "Français"

        case .english:
            return "English"

        }

    }

}

private struct MarketplaceLegalChip: View {

    let title: String
    let icon: String

    var body: some View {

        HStack(spacing:6){

            Image(systemName: icon)

            Text(title)

        }
        .font(.caption.bold())
        .foregroundStyle(.white)
        .padding(.horizontal,10)
        .padding(.vertical,7)
        .background(.white.opacity(0.15))
        .clipShape(Capsule())

    }

}

private struct MarketplaceLegalRow: View {

    let icon: String
    let title: String

    var body: some View {

        HStack(spacing:12){

            MarketplaceIconBadge(
                icon: icon,
                size:40
            )

            Text(title)
                .font(.subheadline.weight(.bold))

            Spacer()

            Image(systemName:"chevron.right")
                .foregroundStyle(.secondary)

        }
        .padding(12)
        .background(.thinMaterial)
        .clipShape(
            RoundedRectangle(
                cornerRadius:20,
                style:.continuous
            )
        )

    }

}
private struct MarketplaceLegalTextBlock: View {
    let title: String
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(.headline, design: .rounded).weight(.black))

            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineSpacing(4)
        }
        .padding(14)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}


#Preview {

    MarketplaceLegalPrivacyView()

}
