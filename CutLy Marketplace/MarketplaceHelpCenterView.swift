//
//  MarketplaceHelpCenterView.swift
//  MonApp
//
//  Created by Thierno Moustapha BARRY  on 02/07/2026.
//

//
//  MarketplaceProfileView.swift
//  MonApp
//
//  Created by Thierno Moustapha BARRY  on 30/06/2026.
//

import SwiftUI

struct MarketplaceHelpCenterView: View {
    
    @State private var searchText = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                
                header
                
                searchBar
                
                helpSection(
                    title: "Premiers pas sur Cutly Marketplace",
                    icon: "sparkles",
                    items: [
                        HelpItem(
                            title: "Qu’est-ce que Cutly Marketplace ?",
                            text: """
Cutly Marketplace est un espace intégré à Cutly qui permet d’acheter, vendre, discuter, suivre des commandes et gérer un profil acheteur-vendeur. Un même utilisateur peut acheter comme client, vendre comme particulier, ou créer une boutique professionnelle.

L’objectif est de permettre aux utilisateurs en Europe, en Afrique et à l’international d’utiliser une marketplace adaptée à leurs réalités : adresses classiques, points de repère, livraison locale, retrait en main propre, Mobile Money, carte bancaire, wallet, support, litiges et sécurité.

Votre profil Marketplace est séparé du reste de l’application afin que vos achats, ventes, favoris, paniers, messages et commandes ne soient jamais mélangés avec ceux d’un autre utilisateur.
"""
                        ),
                        HelpItem(
                            title: "Créer un profil Marketplace",
                            text: """
Pour utiliser toutes les fonctionnalités, vous devez créer un profil Marketplace. Ce profil contient votre nom affiché, votre photo, votre pays, votre ville, votre langue, votre devise, vos moyens de paiement et votre niveau de vérification.

Certaines informations sont visibles publiquement, comme votre photo, votre nom affiché, votre note moyenne, vos ventes publiques et votre statut de confiance. D’autres informations restent privées, comme vos moyens de paiement, vos informations sensibles et vos données de sécurité.

Vous pouvez modifier votre profil plus tard depuis la page Profil Marketplace.
"""
                        )
                    ]
                )
                
                helpSection(
                    title: "Acheter sur la Marketplace",
                    icon: "cart.fill",
                    items: [
                        HelpItem(
                            title: "Comment acheter un produit ?",
                            text: """
Lorsque vous trouvez un produit, vérifiez toujours les photos, le prix, la description, le pays du vendeur, les options de livraison et les avis. Si vous avez un doute, contactez le vendeur avant de payer.

Après paiement, votre commande apparaît dans vos commandes Marketplace. Vous pouvez suivre son état : paiement reçu, préparation, expédition, livraison, litige ou commande terminée.

Pour votre sécurité, évitez les paiements en dehors de Cutly Marketplace. Si vous payez hors plateforme, Cutly ne pourra pas vous protéger en cas de problème.
"""
                        ),
                        HelpItem(
                            title: "Paiement sécurisé",
                            text: """
Cutly Marketplace utilise un système de paiement sécurisé. Selon votre pays, plusieurs moyens peuvent être proposés : carte bancaire, Apple Pay, PayPal, Mobile Money, wallet ou virement.

Certaines méthodes peuvent demander une vérification supplémentaire. Cela protège les acheteurs, les vendeurs et la plateforme contre les fraudes, les faux comptes et les paiements suspects.

Les frais internes de fonctionnement de la plateforme ne sont pas affichés aux utilisateurs dans le parcours d’achat. Le client voit uniquement les informations utiles : prix du produit, livraison, taxes éventuelles, total à payer et statut de commande.
"""
                        )
                    ]
                )
                
                helpSection(
                    title: "Vendre sur la Marketplace",
                    icon: "bag.fill",
                    items: [
                        HelpItem(
                            title: "Publier un produit",
                            text: """
Pour vendre, vous devez avoir un profil Marketplace compatible avec la vente. Vous pouvez publier un produit avec un titre clair, une description précise, un prix, des photos, une catégorie, un état du produit, une localisation et des options de livraison.

Les photos doivent être réelles, nettes et ne pas tromper l’acheteur. Les produits interdits, contrefaits, dangereux ou illégaux peuvent être supprimés automatiquement ou après contrôle.

Un bon vendeur répond rapidement, prépare correctement les colis, respecte les délais et communique clairement avec l’acheteur.
"""
                        ),
                        HelpItem(
                            title: "Recevoir ses revenus",
                            text: """
Lorsqu’une vente est confirmée, les revenus peuvent être placés temporairement en attente jusqu’à la validation de la commande. Ce système protège l’acheteur et le vendeur.

Selon votre pays, vous pourrez recevoir vos revenus via les méthodes disponibles : compte bancaire, PayPal, wallet, Mobile Money ou autre méthode compatible.

Certaines demandes de retrait peuvent être vérifiées pour éviter les fraudes, les usurpations d’identité ou les activités suspectes.
"""
                        )
                    ]
                )
                
                helpSection(
                    title: "Livraison et suivi",
                    icon: "shippingbox.fill",
                    items: [
                        HelpItem(
                            title: "Adresses classiques et adresses flexibles",
                            text: """
Cutly Marketplace est pensée pour plusieurs réalités. Dans certains pays, l’adresse peut être très précise avec rue, numéro, code postal et ville. Dans d’autres régions, l’adresse peut dépendre d’un quartier, d’un point de repère, d’une agence, d’un relais, d’une gare routière, d’un transporteur local ou d’un contact téléphonique.

C’est pourquoi les profils peuvent contenir des informations supplémentaires : point de repère, ville, quartier, pays, numéro de téléphone, GPS, agence de retrait ou instruction spéciale.

Plus l’adresse est claire, plus la livraison sera facile.
"""
                        ),
                        HelpItem(
                            title: "Suivi de commande",
                            text: """
Quand une commande est expédiée, vous pouvez consulter son statut depuis l’espace Commandes ou Suivi. Selon le transporteur, un numéro de suivi peut être disponible.

Si le suivi n’avance pas, contactez d’abord le vendeur. Si le problème persiste, ouvrez un ticket support ou un litige.

Ne confirmez jamais une livraison si vous n’avez pas reçu le produit.
"""
                        )
                    ]
                )
                
                helpSection(
                    title: "Litiges, remboursements et sécurité",
                    icon: "lock.shield.fill",
                    items: [
                        HelpItem(
                            title: "Ouvrir un litige",
                            text: """
Vous pouvez ouvrir un litige si le produit n’est pas reçu, s’il ne correspond pas à la description, s’il est endommagé, si le vendeur ne répond plus ou si une activité semble suspecte.

Un litige doit contenir des preuves : captures d’écran, photos du colis, messages, numéro de suivi, description du problème et toute information utile.

Pendant un litige, le paiement peut rester bloqué jusqu’à décision. Le support analysera les éléments fournis par l’acheteur et le vendeur.
"""
                        ),
                        HelpItem(
                            title: "Protection contre les fraudes",
                            text: """
Cutly Marketplace peut utiliser des contrôles automatiques pour détecter les faux comptes, faux vendeurs, comportements suspects, remboursements anormaux, avis frauduleux, produits interdits ou tentatives de contournement.

Un compte peut être limité, vérifié, suspendu ou bloqué si son comportement met en danger les autres utilisateurs.

Ne partagez jamais votre mot de passe, vos codes de vérification ou vos informations bancaires dans une conversation.
"""
                        )
                    ]
                )
                
                helpSection(
                    title: "Compte, mot de passe et vérification",
                    icon: "person.crop.circle.fill",
                    items: [
                        HelpItem(
                            title: "Connexion et mot de passe oublié",
                            text: """
Vous pouvez vous connecter avec votre adresse e-mail et votre mot de passe. Si vous oubliez votre mot de passe, utilisez le bouton « Mot de passe oublié ». Un lien sécurisé vous sera envoyé par e-mail.

Ce lien permet de créer un nouveau mot de passe. Après modification, retournez dans l’application et connectez-vous avec votre nouvelle information.

Si vous ne recevez pas l’e-mail, vérifiez vos spams, l’adresse saisie et votre connexion internet.
"""
                        ),
                        HelpItem(
                            title: "Vérification e-mail et téléphone",
                            text: """
La vérification permet de confirmer que vous contrôlez réellement l’adresse e-mail ou le numéro de téléphone utilisé. Elle protège votre compte contre les usurpations et améliore la confiance entre acheteurs et vendeurs.

La vérification e-mail fonctionne avec un code temporaire. La vérification SMS sera activée lorsque la configuration Firebase Phone Auth sera totalement stable.
"""
                        )
                    ]
                )
                
                contactSupportCard
                otherContactMethods
                
                
            }
            .padding(.vertical, 20)
        }
        .navigationTitle("Centre d’aide")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground))
    }
    
    private var header: some View {
        VStack(spacing: 12) {
            Image(systemName: "questionmark.circle.fill")
                .font(.system(size: 64, weight: .bold))
                .foregroundStyle(
                    LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
            
            Text("Comment pouvons-nous vous aider ?")
                .font(.title2.bold())
                .multilineTextAlignment(.center)
            
            Text("Retrouvez ici les réponses essentielles sur les achats, ventes, paiements, livraisons, litiges, sécurité, profil et vérification Marketplace.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            
            TextField("Rechercher dans l’aide", text: $searchText)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .padding(.horizontal)
    }
    
    private func helpSection(title: String, icon: String, items: [HelpItem]) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(title, systemImage: icon)
                .font(.title3.bold())
            
            ForEach(items) { item in
                NavigationLink {
                    MarketplaceHelpArticleView(item: item)
                } label: {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 5) {
                            Text(item.title)
                                .font(.headline)
                            
                            Text(item.text)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(3)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .padding(.horizontal)
    }
    private var otherContactMethods: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Autres moyens de nous contacter")
                .font(.title3.bold())

            Button {
                openSupportEmail()
            } label: {
                contactRow(
                    icon: "envelope.fill",
                    color: .blue,
                    title: "Envoyer un e-mail au support",
                    subtitle: "assistance@mycutly.com"
                )
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .padding(.horizontal)
    }

    
    
    
    
    private var contactSupportCard: some View {
        NavigationLink {
            MarketplaceSupportTicketView()
        } label: {
            VStack(spacing: 12) {
                Image(systemName: "headset")
                    .font(.system(size: 42, weight: .bold))
                    .foregroundStyle(.blue)

                Text("Besoin d’une aide personnalisée ?")
                    .font(.headline.bold())

                Text("Envoyez une demande détaillée au support Cutly Marketplace : commande, paiement, livraison, litige, compte, vérification ou vendeur.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Text("Contacter le support")
                    .font(.headline.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(colors: [.purple, .blue], startPoint: .leading, endPoint: .trailing)
                    )
                    .clipShape(Capsule())
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .padding(.horizontal)
        }
        .buttonStyle(.plain)
    }
    
    private func contactRow(
        icon: String,
        color: Color,
        title: String,
        subtitle: String
    ) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.white)
                .frame(width: 48, height: 48)
                .background(color)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
    
    private func openSupportEmail() {
        let email = "assistance@mycutly.com"
        let subject = "Demande d’aide Cutly Marketplace"
        let body = """
    Bonjour l’équipe Cutly,

    J’ai besoin d’aide concernant la Marketplace.

    Sujet :
    Commande / Paiement / Livraison / Litige / Compte / Vérification / Autre

    Expliquez votre problème ici :


    Merci.
    """

        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

        if let url = URL(string: "mailto:\(email)?subject=\(encodedSubject)&body=\(encodedBody)") {
            UIApplication.shared.open(url)
        }
    }
    
    
    
    
}

struct MarketplaceHelpArticleView: View {
    let item: HelpItem

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(item.title)
                    .font(.title.bold())

                Text(item.text)
                    .font(.body)
                    .lineSpacing(6)

                Divider()

                Text("Articles liés")
                    .font(.headline)

                NavigationLink("Voir mes commandes", destination: MarketplaceOrdersView())
                NavigationLink("Gérer mes paramètres", destination: MarketplaceSettingsView())
                NavigationLink("Contacter le support", destination: MarketplaceSupportTicketView())
            }
            .padding()
        }
        .navigationTitle("Article d’aide")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct HelpItem: Identifiable {
    let id = UUID()
    let title: String
    let text: String
}
