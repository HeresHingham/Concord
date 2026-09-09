
//
//  Toast.swift
//  Here's Concord!
//
//  Created by Cameron Conway on 9/1/26.
//
import SwiftUI

struct Toast: Identifiable {
  private(set) var id: String = UUID().uuidString
  var content: AnyView
  var offsetX: CGFloat = 0
  var isDeleting: Bool = false
  
  init(@ViewBuilder content: @escaping (String) -> some View) {
      self.content = .init(content(id))
  }
}

extension View {
    @ViewBuilder
    func interactiveToast(_ toasts: Binding<[Toast]>) -> some View {
        self
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(alignment: .bottom) {
                ToastsView(toasts: toasts)
            }
    }
}

fileprivate struct ToastsView: View {
    @Binding var toasts: [Toast]
    @State private var isExpanded: Bool = false

    var body: some View {
        ZStack(alignment: .bottom) {
            if isExpanded {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .ignoresSafeArea()
            }

            let layout = isExpanded
                ? AnyLayout(VStackLayout(spacing: 10))
                : AnyLayout(ZStackLayout())

            layout {
                ForEach($toasts) { $toast in
                    let index = (toasts.count - 1) - (toasts.firstIndex { $0.id == toast.id } ?? 0)

                    toast.content
                        .offset(x: toast.offsetX)
                        .gesture(
                            DragGesture()
                                .onChanged { value in toast.offsetX = min(0, value.translation.width) }
                                .onEnded { value in
                                    if value.translation.width + (value.velocity.width / 2) < -200 {
                                        $toasts.delete(toast.id)
                                    } else {
                                        toast.offsetX = 0
                                    }
                                }
                        )
                        .visualEffect { [isExpanded] content, _ in
                            content
                                .scaleEffect(isExpanded ? 1 : scale(index), anchor: .bottom)
                                .offset(y: isExpanded ? 0 : offsetY(index))
                        }
                        .transition(.asymmetric(insertion: .offset(y: 100), removal: .move(edge: .leading)))
                }
            }
            .onTapGesture { isExpanded.toggle() }
            .padding(.bottom, 15)
        }
        .animation(.spring, value: isExpanded)
        .onChange(of: toasts.isEmpty) { _, newValue in if newValue { isExpanded = false } }
    }

    nonisolated func offsetY(_ index: Int) -> CGFloat { min(CGFloat(index) * 15, 30) * -1 }
    nonisolated func scale(_ index: Int) -> CGFloat { 1 - min(CGFloat(index) * 0.1, 1) }
}

extension Binding<[Toast]> {
    func delete(_ id: String) {
        if let toast = first(where: { $0.id == id }) {
            toast.wrappedValue.isDeleting = true
        }
        withAnimation(.spring) {
            self.wrappedValue.removeAll { $0.id == id }
        }
    }
}
