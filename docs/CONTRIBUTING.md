## Contributing to NineAnimator

First and foremost, thank you for taking the time to read this document. We are a community of developers and anime lovers, and we need people like you to help in the development of this project.

If you haven't join our [Discord server](https://discord.gg/dzTVzeW) already, feel free to come and find us [there](https://discord.gg/dzTVzeW). You'll get faster responses from our community members and contributors.

In this document, you'll find a set of guidelines for contributing and some resources for getting familiar with NineAnimator's code.

### Table of Contents

- [I just have a question](#i-just-have-a-question)
- [How can I contribute?](#how-can-i-contribute)
- [What should I know before I get started?](#what-should-i-know-before-i-get-started)
    - [Model View Controller](#model-view-controller)
    - [Asynchronous](#asynchronous)
- [Styleguides](#styleguides)
    - [Git Commits](#git-commits)
    - [Swift Styleguide](#swift-styleguide)

### I just have a question

For faster responses, use our [Discord server](https://discord.gg/dzTVzeW) for questions.
* Chances are your question has been answered by one of our moderators. Make sure to check the `#faq` channel and the pinned messages in the `#general` and `#help` channels.
* If you can't find what you're looking for, post your inquiry in the `#help` channel.

Optionally, you can also use our [r/NineAnimator](https://reddit.com/r/NineAnimator) subreddit.

### How can I contribute?

* **Report Bugs**: Use the [issue tracker](https://github.com/SuperMarcus/NineAnimator/issues/new/choose) with the `Bug Report` template to report a bug.
* **Suggesting Enhancements**: Use the [issue tracker](https://github.com/SuperMarcus/NineAnimator/issues/new/choose) with the `Feature Request` template to suggest an enhancement.
* **Help Translating the App**: Use our [Crowdin site](https://translate.9ani.app) at [https://translate.9ani.app](https://translate.9ani.app) to help translate NineAnimator into different langauges.
* **Code Contribution**: Whether you implemented a new anime source or fixed a bug, feel free to open a pull request from your fork. Make sure you read the [styleguides](#styleguides) section.

Feel free to talk to us in our [Discord server](https://discord.gg/dzTVzeW) before contributing.

### What should I know before I get started?

#### Model View Controller

NineAnimator is a typical Cocoa Touch iOS application following the Model-View-Controller (MVC) design pattern. There are many resources online for you to learn the MVC design, but in short, you should know the responsibility of each component and keep the additional code at where it should be.

**Model**: NineAnimator, at its core, is a collection of parsers and analyzers. The `NineAnimator/Models` directory hosts all of the parsing logic and user-configurable.
* **Anime Source**: Under the `Models` folder, you'll find the `Anime Source`. Code under this folder fetches data from different source anime websites, decodes it, and present the information to other components of NineAnimator. For each source website, NineAnimator creates a distinct `Source` class. `Source` encapsulates the functionalities and capabilities of the anime website.
* **Media Parser**: Media Parsers, located under the `Media/Parser` folder in the models, are classes that accept a URL to a streaming site and return a locally streamable URL. Media Parsers are used to support playbacks with native players (and cast). NineAnimator parsers will conform to the `VideoProviderParser` protocol.
* **Anime Listing Service**: The list services are third-party tracking and information services implemented under the `Anime List Service` folder under models. List services conform to the `ListingService` protocol and declare their capabilities through the `var isCapableOf<capability>: Bool` getters. List services also provide the matching `ListingAnimeReference` for each `AnimeLink`.

**View**: The views define the look and feel of the UI components. NineAnimator employs several mechanisms to construct and configure the UI. In general, NineAnimator's design follows that of the latest iOS system apps.
* **Storyboards and Xibs**: NineAnimator defines most of the UIs with storyboards. We also use auto-layout extensively for adaptive layouts and device variants.
* **Theme**: Although iOS 13 introduced the system-wide dark mode, to enable backward compatibility with older systems, we still employ our own theming system for light and dark appearances. Each UI component is manually added by `Theme.provision()` (or, for subclasses of `UIView`, `.makeThemable()`). Subclasses of `UIView` can either implicitly or explicitly support the theming system. By default, the theming system will configure the views according to types. By conforming to the `Themable` protocol, you're explicitly stating support for the theme system and waiving the default behaviors.

**Controllers**: Controllers of NineAnimator manages the internal flow and logics.
* **View Controllers**: View controllers instantiate and manage views. In most cases, there will be a convenient method for instantiating view controllers. Optionally, view controllers are also linked by storyboard references. The following is a list of common view controllers in NineAnimator.
    * **AnimeViewController**: The `AnimeViewController` class fetches and presents the correspond `Anime` object of an `AnimeLink`. Create the `AnimeViewController` using storyboard, then use the `setPresenting()` method to configure.
    * **NativePlayerController**: The `NativePlayerController` class manages local playbacks of the retrieved `PlaybackMedia` instances. You don't instantiate `NativePlayerController` directly. Instead, you use the `NativePlayerController.default` singleton to retrieve the shared instance and call the `play()` method to start playback.
    * **CastController**: The `CastController` manages external playbacks such as Google Cast. Use `CastController.default` to retrieve the singleton. Use the `presentPlaybackController()` to present the casting interface. Use the `var isReady: Bool` getter to check if a device has been selected and is ready for playback.
* **UserNotificationManager**: The `UserNotificationManager` manages and update anime subscriptions. Use the `UserNotificationManager.default` singleton to retrieve the shared manager.
* **OfflineContentManager**: The `OfflineContentManager` hosts NineAnimator's download system. Use the `OfflineContentManager.shared` singleton to access the shared manager.

#### Asynchronous

Most operations in NineAnimator are performed asynchronously (optionally on a different thread). This ensures that any time consuming or intensive tasks won't block the main thread.

At the center of NineAnimator's asynchronous framework is the [`NineAnimatorPromise` class](https://github.com/SuperMarcus/NineAnimator/blob/master/NineAnimator/Utilities/Asynchronous/Promise.swift). This class borrows the idea of promise and bridges the legacy callback mechanisms.

> Note: As a safety measure, be sure to keep and reference to the promise instance for the duration of the task. Loosing reference to an unresolved promise will result in the executing task being cancelled. Inside the promise, all references to the blocks or tasks will be removed as soon as the promise task returns.

```Swift
let promise = NineAnimatorPromise.firstly {
    () -> Int in
    var result: Int
    // Pefrom some operations...
    return result
} .then {
    previousResult -> Int in
    var result: Int
    // Some additional operations...
    return result
} .thenPromise {
    previousResult -> NineAnimatorPromise<Int> in
    // Return a promise
    .firstly {
        var result: Int
        // Perform some more operations...
        return result
    }
} .defer {
    thisPromise in
    // This block is executed whenever the promises to this point finish
    // executing, regardless of success or failiure.
} .error {
    error in
    // Called when the promise is rejected with an error
} .finally {
    finalResult in
    // Called when the promise is resolved (successfully)
    // All previous promises are not executed until the `finally` block
    // is added.
}
```

### Styleguides

#### Git Commits

In general, use descriptive languages for commit messages. Explain what you add, changed, or deleted ("Fix a problem that causes the app to crash in the Library scene" not "fix a problem"). Reference any issue if the commit is related to one.

Before committing, make sure the compiler doesn't complain and `swiftlint` doesn't give out warnings.

Avoid trivial ("Oops!") commits. Whenever possible, amend your existing commits before pushing or submitting a pull request.

Do as much as related in a single commit. For example, if you're renaming a list of files, don't commit for each rename operation. Instead, commit once for all name changes.

#### Swift Styleguide

A few points to keep in mind:

* Use implicit returns for single-line functions and closures.
* Avoid implicit unwrapping properties and variables (`var data: Data! { get }`).
* Prefer shorter class names (`LibrarySceneController` not `LibraryTabSceneCollectionViewController`).
* Prefer extensions over single files. Split large files into multiple smaller files with `+` extensions (ex. `User.swift`, `User+Preferences.swift`, `User+History.swift`).
* Avoid yoda conditions. Keep constants intuitively to the right (ex. `x == 5` not `5 == x`).

We use `swiftlint` to ensure the tidyness of our code. Before submitting your code, run `swiftlint` to check for potential styling violations.