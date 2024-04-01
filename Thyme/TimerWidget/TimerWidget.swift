import ActivityKit
import WidgetKit
import SwiftUI

struct TimerActivityView: View {
    let context: ActivityViewContext<TimerAttributes>
    
    var body: some View {

        VStack (alignment: .center) {
            Text(context.attributes.timerName)
                .font(.headline)
            Spacer()
            HStack {
                Spacer()
                Text(context.state.endTime, style: .timer)
                    .font(.title)
            }

        }
        .padding()

    }
}


@main
struct Tutorial_Widget: Widget {
    let kind: String = "Tutorial_Widget"
    
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TimerAttributes.self) { context in
            TimerActivityView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                }

                // Expanded region
                DynamicIslandExpandedRegion(.trailing) {
                }

                // Bottom region
                DynamicIslandExpandedRegion(.bottom) {
                }
            }
            compactLeading: {
                // ...
            } compactTrailing: {
                // ...
            } minimal: {
                // ...
            }
        }
    }
}
