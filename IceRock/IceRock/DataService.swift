import Foundation

final class DataService {

    static func generateCandles(startPrice: Double, count: Int,
                                 volatility: Double, seed: UInt64) -> [CandleData] {
        var out: [CandleData] = []
        var price = startPrice
        var rng = SeededRNG(seed: seed)
        var date = Calendar.current.date(byAdding: .day, value: -count, to: Date())!

        for _ in 0..<count {
            let open  = price
            let trend = (rng.next() - 0.47) * volatility * price
            let close = open + trend
            let range = abs(trend) + rng.next() * volatility * price * 0.3
            let high  = max(open, close) + rng.next() * range * 0.5
            let low   = max(min(open, close) - rng.next() * range * 0.5, price * 0.5)
            let vol   = Int(rng.next() * 5_000_000) + 100_000

            out.append(CandleData(date: date, open: open, high: high,
                                  low: low, close: close, volume: vol))
            price = close
            date = Calendar.current.date(byAdding: .day, value: 1, to: date)!
            while Calendar.current.component(.weekday, from: date) == 1 ||
                  Calendar.current.component(.weekday, from: date) == 7 {
                date = Calendar.current.date(byAdding: .day, value: 1, to: date)!
            }
        }
        return out
    }

    static func generateAssets() -> [Asset] {
        typealias P = (String, String, String, Int, Double, Double, Double, Double, UInt64)
        let params: [P] = [
            ("SBER",   "Сбербанк",    "Финансы",    1200,  268.5, 0.022, 1.8,  240.0,  42),
            ("GAZP",   "Газпром",     "Энергетика",  800,  154.2, 0.025, 2.4,  148.0,  77),
            ("LKOH",   "Лукойл",      "Нефть/газ",   300, 6820.0, 0.018, 2.1, 6500.0,  99),
            ("YNDX",   "Яндекс",      "Технологии",  450, 3250.0, 0.032, 3.6, 3000.0, 123),
            ("GMKN",   "НорНикель",   "Металлы",     180,15400.0, 0.020, 3.1,16000.0, 156),
            ("ROSN",   "Роснефть",    "Нефть/газ",   650,  520.0, 0.021, 2.3,  500.0, 200),
            ("GOLD",   "Золото",       "Сырьё",        50, 5620.0, 0.015, 1.4, 5400.0, 211),
            ("USDRUB", "Доллар США",  "Валюта",     2000,   84.2, 0.012, 2.8,   82.0, 333),
            ("OFZ238", "ОФЗ 26238",   "Облигации",  5000,  612.0, 0.008, 0.8,  600.0, 444),
            ("MGNT",   "Магнит",      "Ритейл",      220, 5800.0, 0.024, 2.9, 5600.0, 555),
        ]
        return params.map { p in
            let candles = generateCandles(startPrice: p.7, count: 120,
                                          volatility: p.5, seed: p.8)
            let cur  = candles.last?.close  ?? p.7
            let prev = candles.dropLast().last?.close ?? p.7
            return Asset(ticker: p.0, name: p.1, sector: p.2, tickCount: p.3,
                         avgPrice: p.4, currentPrice: cur, prevPrice: prev,
                         personalRisk: p.6, candles: candles)
        }
    }

    static func generateNews() -> [NewsItem] {
        let cal = Calendar.current
        let now = Date()
        func ago(_ d: Int) -> Date { cal.date(byAdding: .day, value: -d, to: now)! }
        return [
            NewsItem(source: "РБК",
                     title: "Россия наращивает золотые резервы: +12 тонн за квартал",
                     body: "Банк России сообщил об увеличении золотого запаса страны. Эксперты ожидают продолжения тренда.",
                     relatedTicker: "GOLD", date: ago(1)),
            NewsItem(source: "Ведомости",
                     title: "Сбербанк повысил ставки по ипотеке до 18,5%",
                     body: "Решение принято после заседания ЦБ РФ. Аналитики ожидают охлаждения рынка жилья.",
                     relatedTicker: "SBER", date: ago(2)),
            NewsItem(source: "Коммерсантъ",
                     title: "Газпром подписал СПГ-контракты с Азией на 15 лет",
                     body: "Долгосрочные соглашения с КНР и Индией. Поставки начнутся в I кв. следующего года.",
                     relatedTicker: "GAZP", date: ago(3)),
            NewsItem(source: "Forbes Russia",
                     title: "Яндекс запускает B2B-облако для корпораций",
                     body: "Акции выросли на 3,2% по итогам торгового дня после объявления о новом продукте.",
                     relatedTicker: "YNDX", date: ago(3)),
            NewsItem(source: "Forbes Russia",
                     title: "Лукойл выплатит рекордные дивиденды: 1 100 ₽ на акцию",
                     body: "Совет директоров рекомендовал исторически максимальные выплаты. Реестр — 15 июля.",
                     relatedTicker: "LKOH", date: ago(4)),
            NewsItem(source: "ТАСС",
                     title: "ЦБ РФ сохранил ключевую ставку на уровне 16%",
                     body: "Регулятор указал на инфляционное давление. ОФЗ отреагировали ростом доходностей.",
                     relatedTicker: "OFZ238", date: ago(5)),
            NewsItem(source: "РБК",
                     title: "Доллар превысил 91 рубль впервые за три месяца",
                     body: "Ослабление рубля связано с ростом импорта и сезонным спросом на валюту.",
                     relatedTicker: "USDRUB", date: ago(6)),
            NewsItem(source: "Ведомости",
                     title: "Норникель сократит производство палладия на 8%",
                     body: "Компания скорректировала план из-за ремонта на Октябрьском руднике.",
                     relatedTicker: "GMKN", date: ago(7)),
            NewsItem(source: "Коммерсантъ",
                     title: "Магнит открыл 200 магазинов в малых городах",
                     body: "Ритейлер ускорил региональную экспансию. Ожидается 600+ новых точек за год.",
                     relatedTicker: "MGNT", date: ago(8)),
            NewsItem(source: "Интерфакс",
                     title: "Роснефть получила лицензию на арктический шельф",
                     body: "Выданы разрешения на геологоразведку в трёх блоках Карского моря.",
                     relatedTicker: "ROSN", date: ago(9)),
        ]
    }

    static func generateDividends() -> [DividendEvent] {[
        DividendEvent(ticker:"LKOH",  company:"Лукойл",    date:"15.07.2025", amount:"1 100 ₽/акц", yield:"8.4%"),
        DividendEvent(ticker:"SBER",  company:"Сбербанк",  date:"23.07.2025", amount:"33.5 ₽/акц",  yield:"6.1%"),
        DividendEvent(ticker:"MGNT",  company:"Магнит",    date:"02.08.2025", amount:"412 ₽/акц",   yield:"5.2%"),
        DividendEvent(ticker:"GAZP",  company:"Газпром",   date:"10.08.2025", amount:"25.0 ₽/акц",  yield:"4.8%"),
        DividendEvent(ticker:"ROSN",  company:"Роснефть",  date:"28.08.2025", amount:"38.6 ₽/акц",  yield:"4.1%"),
        DividendEvent(ticker:"GMKN",  company:"НорНикель", date:"15.09.2025", amount:"780 ₽/акц",   yield:"3.9%"),
        DividendEvent(ticker:"OFZ238",company:"ОФЗ 26238", date:"20.09.2025", amount:"37.9 ₽/бум",  yield:"6.0%"),
    ]}

    static func generateScreener() -> [ScreenerRow] {[
        ScreenerRow(ticker:"SBER", name:"Сбербанк",  pe:5.1,  divYield:6.1, roe:23.4, beta:0.85, cap:6420),
        ScreenerRow(ticker:"GAZP", name:"Газпром",   pe:3.2,  divYield:4.8, roe:11.2, beta:0.72, cap:3150),
        ScreenerRow(ticker:"LKOH", name:"Лукойл",    pe:6.4,  divYield:8.4, roe:19.6, beta:0.91, cap:5200),
        ScreenerRow(ticker:"YNDX", name:"Яндекс",    pe:28.7, divYield:0.0, roe:12.1, beta:1.41, cap:1820),
        ScreenerRow(ticker:"GMKN", name:"НорНикель", pe:8.9,  divYield:3.9, roe:31.2, beta:0.78, cap:2780),
        ScreenerRow(ticker:"ROSN", name:"Роснефть",  pe:4.6,  divYield:4.1, roe:14.3, beta:0.88, cap:4100),
        ScreenerRow(ticker:"MGNT", name:"Магнит",    pe:11.2, divYield:5.2, roe:22.8, beta:0.95, cap:1640),
    ]}
}

struct SeededRNG {
    private var state: UInt64
    init(seed: UInt64) { self.state = seed == 0 ? 1 : seed }
    mutating func next() -> Double {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return Double(state & 0x001FFFFFFFFFFFFF) / Double(0x001FFFFFFFFFFFFF)
    }
}
