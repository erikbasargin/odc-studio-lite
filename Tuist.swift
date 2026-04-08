import ProjectDescription

let tuist = Tuist(
    fullHandle: "erik-basargin/odc-studio-lite",
    cache: .cache(
        upload: Environment.isCI,
    ),
    project: .tuist(
        swiftVersion: "6.3",
        generationOptions: .options(
            enableCaching: true,
        ),
    ),
)
