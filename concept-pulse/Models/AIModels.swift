import SwiftUI
import PhotosUI

// MARK: - Chat Models

enum MessageSender {
    case user, assistant
}

enum MessageContent {
    case text(String)
    case image(UIImage, caption: String?)
    case analysisResult(AnalysisResult)
}

struct AnalysisResult {
    let title: String
    let summary: String
    let tags: [AnalysisTag]
    let disclaimer: String
}

struct AnalysisTag: Identifiable {
    let id = UUID()
    let label: String
    let color: Color
}

struct ChatMessage: Identifiable {
    let id = UUID()
    let sender: MessageSender
    let content: MessageContent
    let timestamp: Date
}

// MARK: - Quick Prompts

struct QuickPrompt: Identifiable {
    let id = UUID()
    let icon: String
    let textAr: String
    let color: Color
}

enum AIPrompts {
    static let quickPrompts: [QuickPrompt] = [
        .init(icon: "pills.fill",         textAr: "ما أعراض ارتفاع الضغط؟",   color: Color(red: 0.90, green: 0.40, blue: 0.45)),
        .init(icon: "heart.text.square",  textAr: "ما هي نصائح صحة القلب؟",   color: Color(red: 0.40, green: 0.70, blue: 0.85)),
        .init(icon: "figure.walk",        textAr: "كم ساعة نوم يحتاج الجسم؟", color: Color(red: 0.50, green: 0.75, blue: 0.60)),
        .init(icon: "fork.knife",         textAr: "نظام غذائي صحي مقترح",      color: Color(red: 0.95, green: 0.70, blue: 0.40)),
        .init(icon: "cross.case.fill",    textAr: "متى أراجع الطوارئ؟",       color: Color(red: 0.75, green: 0.55, blue: 0.85)),
        .init(icon: "brain.head.profile", textAr: "كيف أقلل التوتر؟",          color: Color(red: 0.85, green: 0.55, blue: 0.70))
    ]
}

// MARK: - Sample Conversation

enum SampleConversation {
    static let messages: [ChatMessage] = [
        ChatMessage(
            sender: .assistant,
            content: .text("مرحباً! أنا مساعدك الطبي الذكي 👋\n\nيمكنني مساعدتك في:\n• الإجابة على أسئلتك الصحية\n• تحليل الصور الطبية\n• فهم نتائج الفحوصات\n\n⚠️ تذكير: مشوراتي لأغراض توعوية فقط، وتُكمّل ولا تُغني عن استشارة طبيبك."),
            timestamp: Date().addingTimeInterval(-300)
        )
    ]

    static func aiReply(for query: String) -> String {
        let responses: [String: String] = [
            "ضغط": "ارتفاع ضغط الدم يُسمى «القاتل الصامت» لأنه غالباً لا تظهر له أعراض واضحة.\n\n**الأعراض الشائعة:**\n• صداع متكرر في مؤخرة الرأس\n• طنين في الأذنين\n• دوخة وزغللة\n• ضيق في التنفس\n\n**التوصية:** قياس الضغط بانتظام والحد من الملح. إذا تجاوز ١٤٠/٩٠ استشر طبيبك فوراً. 💙",
            "قلب": "للحفاظ على صحة القلب اتبع هذه النصائح الذهبية:\n\n❤️ **الغذاء:** أقل دهون مشبعة، أكثر خضروات وأسماك\n🚶 **الحركة:** ٣٠ دقيقة مشي يومياً على الأقل\n😴 **النوم:** ٧-٨ ساعات ليلياً\n🚭 **التدخين:** الإقلاع فوري ومُنقذ للحياة\n📊 **المتابعة:** فحص الكوليسترول والضغط دورياً\n\nقلبك يستحق العناية! 💪",
            "نوم": "الجسم البالغ يحتاج **٧ إلى ٩ ساعات** من النوم يومياً.\n\n✅ **فوائد النوم الكافي:**\n• تعزيز المناعة والذاكرة\n• توازن الهرمونات وضبط الوزن\n• صحة القلب والأوعية الدموية\n\n💡 **نصيحة:** حاول النوم في توقيت ثابت كل يوم، وأطفئ الشاشات قبل ٣٠ دقيقة من النوم.",
            "غذاء": "إليك نظام غذائي صحي متوازن:\n\n🌅 **الإفطار:** شوفان + فاكهة + بيض مسلوق\n☀️ **الغداء:** بروتين خفيف (دجاج/سمك) + خضروات + حبوب كاملة\n🌙 **العشاء:** وجبة خفيفة قبل النوم بساعتين\n\n🥤 اشرب ٨ أكواب ماء يومياً\n🍎 ٥ حصص فاكهة وخضروات يومياً\n\nتذكر: الاستمرارية أهم من الكمال! 🌿",
            "توتر": "التوتر المزمن يؤثر سلباً على الصحة الجسدية والنفسية.\n\n🧘 **تقنيات فعّالة:**\n• تنفس عميق: شهيق ٤ ثوانٍ، حبس ٤، زفير ٦\n• المشي في الطبيعة ١٥ دقيقة\n• كتابة اليوميات قبل النوم\n• تحديد أولويات المهام\n\n💬 إذا استمر التوتر أكثر من أسبوعين، لا تتردد في استشارة متخصص نفسي. أنت لست وحدك 💙",
            "طوارئ": "اطلب الإسعاف فوراً (٩١١) في هذه الحالات:\n\n🔴 **حرجة:**\n• ألم صدري شديد أو ضيق تنفس مفاجئ\n• فقدان الوعي أو شلل مفاجئ\n• نزيف لا يتوقف\n• حرق شديد أو حادث\n\n🟡 **عاجلة (أقسام الطوارئ):**\n• حمى تتجاوز ٣٩.٥°\n• كسر أو التواء مؤلم\n• ألم شديد مفاجئ\n\nصحتك أهم شيء — لا تتردد أبداً! 🚑"
        ]

        for (key, reply) in responses {
            if query.contains(key) { return reply }
        }
        return "شكراً على سؤالك! 🤔\n\nيبدو أن سؤالك يحتاج إلى إجابة دقيقة. لضمان حصولك على معلومات موثوقة بخصوص **«\(query)»**، أنصحك بـ:\n\n• استشارة طبيب متخصص\n• زيارة موثوقة مثل موقع المنظمة الصحية السعودية\n\nهل يمكنني مساعدتك بسؤال آخر؟ 💙"
    }

    static let sampleAnalysis = AnalysisResult(
        title: "تحليل الصورة الطبية",
        summary: "تمت معالجة الصورة المرفقة بنجاح. يبدو أن الصورة تظهر منطقة جلدية تستدعي المتابعة. **ننصح بمراجعة طبيب جلدي** للتشخيص الدقيق.",
        tags: [
            .init(label: "جلدية", color: Color(red: 0.75, green: 0.55, blue: 0.85)),
            .init(label: "يحتاج متابعة", color: Color(red: 0.96, green: 0.76, blue: 0.36)),
            .init(label: "غير حرجة", color: Color(red: 0.30, green: 0.72, blue: 0.55))
        ],
        disclaimer: "هذا التحليل أولي وتثقيفي فقط، ولا يُعدّ تشخيصاً طبياً."
    )
}
