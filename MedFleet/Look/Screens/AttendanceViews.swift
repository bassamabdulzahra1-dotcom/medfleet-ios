import SwiftUI

// MARK: - البصمة (للموظف)

struct AttendanceView: View {
    let user: AppUser
    @Environment(AppStore.self) private var store

    @State private var record: AttendanceRecord?
    @State private var mode: AttendanceAction = .checkIn
    @State private var fp: FpState = .idle
    @State private var headline: String?
    @State private var subline: String?
    @State private var toast: String?
    @State private var resetTask: Task<Void, Never>?

    private var label: String { mode == .checkIn ? "الحضور" : "الانصراف" }

    var body: some View {
        ZStack(alignment: .bottom) {
            ScreenScroll {
                PageHeader(title: "الحضور", subtitle: "\(user.name) · \(user.jobTitle)", subtitleAbove: true)

                LiveClock { now in
                    VStack(spacing: 8) {
                        (Text(hm(now)).font(MFFont.display(58, .ultraLight)).foregroundColor(MF.ink)
                            + Text("  \(amPm(now))").font(MFFont.body(20)).foregroundColor(MF.goldText))
                            .environment(\.layoutDirection, .leftToRight)
                        Text(fullDate(now)).font(MFFont.body(13.5)).foregroundStyle(MF.ink2)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.top, 22)

                Segmented(options: [(AttendanceAction.checkIn, "حضور"), (AttendanceAction.checkOut, "انصراف")], value: $mode)
                    .padding(.horizontal, 24)
                    .padding(.top, 22)
                    .disabled(fp == .busy)

                FingerprintButton(state: fp, label: "المس لتسجيل \(label)") { Task { await scan() } }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 10)

                VStack(spacing: 4) {
                    Text(headline ?? "المس للتحقق ببصمتك").font(MFFont.display(18, .medium)).foregroundStyle(MF.ink)
                    Text(subline ?? "لتسجيل \(label) باستخدام بصمة هاتفك").font(MFFont.body(13)).foregroundStyle(MF.ink2)
                }
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)

                LiveClock { now in
                    let worked = record?.worked(until: now)
                    HStack(spacing: 0) {
                        todayCell("الحضور", time12OrDash(record?.checkIn))
                        Rectangle().fill(MF.line).frame(width: 1, height: 36)
                        todayCell("الانصراف", time12OrDash(record?.checkOut))
                        Rectangle().fill(MF.line).frame(width: 1, height: 36)
                        todayCell("ساعات العمل", worked.map(durationText) ?? "—")
                    }
                    .padding(.vertical, 14)
                    .padding(.horizontal, 6)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .softShadow()
                }
                .padding(.top, 24)

                if let r = record {
                    Text("بداية الشفت \(r.shiftText)")
                        .font(MFFont.body(12)).foregroundStyle(MF.ink3)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 10)
                }
            }

            if let toast {
                Text(toast)
                    .font(MFFont.body(14))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .background(MF.ink, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .padding(.bottom, 120)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeOut(duration: 0.2), value: toast)
        .task {
            let r = await store.repo.myAttendanceToday(user)
            record = r
            mode = (r.checkIn != nil && r.checkOut == nil) ? .checkOut : .checkIn
        }
    }

    private func todayCell(_ label: String, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text(label).font(MFFont.body(11.5)).foregroundStyle(MF.ink2)
            Text(value).font(MFFont.display(15, .medium)).foregroundStyle(MF.ink)
        }
        .frame(maxWidth: .infinity)
    }

    private func showToast(_ text: String) {
        toast = text
        Task {
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            if toast == text { toast = nil }
        }
    }

    private func show(_ state: FpState, _ h: String, _ s: String) {
        resetTask?.cancel()
        fp = state
        headline = h
        subline = s
        if state == .success || state == .failure {
            resetTask = Task {
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                guard !Task.isCancelled else { return }
                fp = .idle
                headline = nil
                subline = nil
            }
        }
    }

    @MainActor
    private func scan() async {
        guard let r = record else { return }
        if mode == .checkIn, let at = r.checkIn { showToast("سجّلت حضورك مسبقاً الساعة \(time12(at))"); return }
        if mode == .checkOut, r.checkIn == nil { showToast("سجّل حضورك أولاً"); return }
        if mode == .checkOut, let at = r.checkOut { showToast("سجّلت انصرافك مسبقاً الساعة \(time12(at))"); return }

        let action = mode
        let actionLabel = label
        show(.busy, "جارِ التحقق…", "ضع إصبعك على المستشعر")

        switch await BiometricAuth.authenticate(reason: "تسجيل \(actionLabel)") {
        case .success:
            do {
                let updated = try await store.repo.registerAttendance(user, action: action, at: Date())
                record = updated
                store.attendanceVersion += 1
                if action == .checkIn { mode = .checkOut }
                let at = action == .checkIn ? updated.checkIn : updated.checkOut
                show(.success, "تم تسجيل \(actionLabel)", "الساعة \(time12OrDash(at)) · تم التحقق من الهوية")
            } catch {
                show(.failure, "تعذّر الحفظ على الخادم", "تأكد من الإنترنت وأعد المحاولة")
            }
        case .failed:
            show(.failure, "لم يتم التحقق", "حاول مرة أخرى")
        case .unavailable:
            show(.idle, "البصمة غير مفعّلة", "فعّل البصمة من إعدادات الهاتف ثم حاول مجدداً")
        case .error:
            show(.failure, "تعذّر الوصول للمستشعر", "أعد المحاولة بعد قليل")
        }
    }
}

// MARK: - حضور الفريق (للمدير — عرض فقط)

enum RangeKind: Hashable { case day, week, month }

struct TeamAttendanceView: View {
    @Environment(AppStore.self) private var store
    @Environment(Router.self) private var router
    @State private var range = RangeKind.day
    @State private var records: [AttendanceRecord]?

    var body: some View {
        ScreenScroll(bottom: 32) {
            PageHeader(
                title: "حضور الفريق",
                subtitle: fullDate(Date()),
                onBack: { router.pop() },
                trailing: AnyView(CircleIconButton(systemName: "square.and.arrow.down", label: "تصدير التقرير", tint: MF.goldText) {})
            )
            Segmented(options: [(RangeKind.day, "اليوم"), (RangeKind.week, "الأسبوع"), (RangeKind.month, "الشهر")], value: $range)
                .padding(.top, 16)

            if let list = records {
                PineCard(padding: 20, ringsCenter: UnitPoint(x: -0.08, y: -0.6), ringsRadius: 110) {
                    HStack {
                        count(MF.mint, "حاضر", list.filter { $0.status == .present }.count)
                        count(MF.gold, "متأخر", list.filter { $0.status == .late }.count)
                        count(MF.dangerSoft, "غائب", list.filter { $0.status == .absent }.count)
                    }
                }
                .padding(.top, 14)

                SectionHeader(title: "الفريق").padding(.top, 20)
                if list.isEmpty {
                    EmptyCard(text: "لا يوجد موظفون")
                } else {
                    GroupedList(list) { r in
                        let pill = pillStyle(r.status)
                        ListRow(
                            title: r.employeeName,
                            subtitle: "حضور \(time12OrDash(r.checkIn)) · انصراف \(time12OrDash(r.checkOut))",
                            minHeight: 74,
                            leading: AnyView(IconTile(text: String(r.employeeName.prefix(1)), bg: MF.goldTint, fg: MF.goldText, size: 46, radius: 23)),
                            trailing: AnyView(StatusPill(label: pill.0, bg: pill.1, fg: pill.2))
                        )
                    }
                }
            } else {
                LoadingView()
            }
        }
        // TODO: مرّر نطاق الأسبوع/الشهر للـ API عند الربط
        .task(id: range) {
            records = nil
            records = await store.repo.teamAttendance(day: Date())
        }
    }

    private func pillStyle(_ s: AttendanceStatus) -> (String, Color, Color) {
        switch s {
        case .present: return ("حاضر", MF.successTint, MF.successText)
        case .late: return ("متأخر", MF.warnTint, MF.warnText)
        case .absent: return ("غائب", MF.dangerTint, MF.danger)
        }
    }

    private func count(_ dot: Color, _ label: String, _ value: Int) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            LegendDot(color: dot, label: label, textColor: MF.onPineMuted)
            Text("\(value)").font(MFFont.display(28, .light)).foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
