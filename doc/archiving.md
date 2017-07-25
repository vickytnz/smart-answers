# How to archive a Smart Answer

As archiving tends not to be temporary, it's preferable to remove the flow entirely - and it can always be recovered from `git` history.

If a flow needs to be removed urgently then it be can archived quickly by changing the flow's status to 'archived'. You should make sure work is scheduled to properly clean up the, now, unused flows.

Once a flow has been removed the artefact will no longer register itself when the Smart Answers application is released.

You will then need to add a redirect in [router-data](https://github.gds/gds/router-data) for the artefact slug. This should be a `prefix` route, so all parts of the Smart Answer URL are matched and preserved. ([This is a good example](https://github.digital.cabinet-office.gov.uk/gds/router-data/pull/336))

## Flow file naming convention

Files associated to a flow are generally named to match the slug of the flow, eg, `pay-leave-for-parents` may have files named `pay-leave-for-parents.yml` or `pay_leave_for_parents.rb`, depending on the naming convention of the file type.

It's advisable to search the repo for both underscore and snake-case variations of the name.

## Removing a Ruby/YML Smart Answer

Remove these files:

- `lib/smart_answer_flows` has a `.rb` file matching the name of the flow
- `lib/smart_answer_flows/locales/en` has a `.yml` file matching the name of the flow
- `test/integration/smart_answer_flows/` has a `_test.rb`, matching the name of the flow

There may also be an associated `Calculator` or data files, these will be referenced from the `.rb` flow. For example: `Calculators::PlanPaternityLeave.new(due_date: due_date)`

- Calculators can be found in `https://github.com/alphagov/smart-answers/tree/master/lib/smart_answer/calculators` - ensure they're not used by any other flows.
- There may be some flow specific data in `lib/data` - again, ensure thats not used by any other flows.

Generally, the larger and more complex the Smart Answer, the more likely there may be additional supporting files, and you should check the flow carefully and get review from someone more familiar with Smart Answers.

This [pull request](https://github.com/alphagov/smart-answers/pull/1428) is a good example of removing this kind of Smart Answer.
