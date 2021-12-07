# SupabaseAnalytics

Analytics provides insight on app usage and user engagement. Its reports help you understand clearly how your users behave, which enables you to make informed decisions regarding app marketing and performance optimizations.

## Get started with Analytics
Create a table called `analytics` on the database:

```sql
create table public.analytics (
  name text not null,
  params json,
  user_id text,
  timestamp text
);
```

Initialize the analytics addon:

```swift
let client: SupabaseClient = ...
SupabaseAnalytics.initialize(client: client);
```

### Log an event
After initialized, you can log the events using `SupabaseAnalytics.logEvent(name:params:)`.

### Auth events
When the user is signed in or signed up, the `user_session` event is triggered automatically.

You can disable the automatic logging when initializing by passing `logUserSignIn: false`.

### Log User Identifier
The `user_id` is logged on every event automatically. You can disable this when initializing by passing `useLoggedUserInfo: false`.
