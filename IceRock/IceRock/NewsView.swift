import SwiftUI

struct NewsView: View {
    @EnvironmentObject var vm: PortfolioViewModel

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 10) {
                        ForEach(vm.news) { item in
                            NewsCardView(item: item)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Новости")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color(hex: "#0c1020"), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }
}

struct NewsCardView: View {
    let item: NewsItem

    private var accentColor: Color { Color.appAccent }

    private var formattedDate: String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "ru_RU")
        df.dateFormat = "d MMMM yyyy"
        return df.string(from: item.date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                HStack(spacing: 5) {
                    Image(systemName: "newspaper.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.appAccent)
                    Text(item.source)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.appAccent)
                }

                Text("[" + item.relatedTicker + "]")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.appGreen)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.appGreen.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 5))

                Spacer()

                Text(formattedDate)
                    .font(.system(size: 10))
                    .foregroundColor(.appTextSecondary)
            }

            Text(item.title)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.appTextPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Text(item.body)
                .font(.system(size: 12))
                .foregroundColor(.appTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .background(Color.appCard)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.appBorder, lineWidth: 1)
        )
        .overlay(
            Rectangle()
                .fill(Color.appAccent)
                .frame(width: 4)
                .clipShape(RoundedRectangle(cornerRadius: 2)),
            alignment: .leading
        )
    }
}
