import ProjectDescription

let tuist = Tuist(
    fullHandle: "erik-basargin/odc-studio-lite",
    project: .tuist(
        swiftVersion: "6.3",
        generationOptions: .options(
            enableCaching: Environment.enableCaching.getBoolean(default: false),
        ),
    ),
)
