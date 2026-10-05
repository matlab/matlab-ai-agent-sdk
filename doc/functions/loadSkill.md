# loadSkill
<a id="loadskill"></a>

Load skill into agent
## Syntax
<a id="syntax"></a>

`loadSkill(agent,skill)`

`loadSkill(agent,skillResource)`
## Description
<a id="description"></a>

Agents can decide to load skills into their message history, based on the user
prompt. You can also manually load skills by using the `loadSkill`
function.

Skills are supplemental text information that can improve the quality of the output of an AI agent. They
typically explain how to perform a particular task or workflow.
Skills can be long and detailed, so to conserve tokens, agents only load them when
necessary.

`loadSkill(agent,skill)`
loads the content of the `SKILL.md` file of a skill
`skill` into the message history of the AI agent
`agent`.

`loadSkill(agent,skillResource)`
loads the content of the skill resource `skillResource` into the message
history of the agent.
## Examples
<a id="examples"></a>
### Run Agent With Skills
<a id="run-agent-with-skills"></a>

This example shows how to load a specific skill into the message
history of an AI agent.

Assume you have a skills directory of the
form:

```
my-skill-directory/
  my-favorite-skill/
    SKILL.md
    references/
      my-supplemental-information.md
  my-second-favorite-skill
    SKILL.md
```

Create the agent from an LLM client `client` by using the
[`aisdk.AIAgent`](aisdk.AIAgent.md) function. Suppress the command line output of the agent by setting
`DisplayMode` to `"off"`. Provide the agent with
your skills by specifying the `SkillDirectories` name-value
argument.

```
agent = aisdk.AIAgent(client,DisplayMode="off",SkillDirectories="./my-skill-directory");
```

Inspect the `Skills` property of the agent.

```
agent.Skills
```

```
ans =

  2×1 string array

    "my-favorite-skill"
    "my-second-favorite-skill"
```

Instruct the agent to perform a task by using the first
skill.

```
run(agent,"Perform my favorite task by using my favorite skill.");
```

Inspect the message
history.

```
agent.Messages
```

```
ans =

  1×4 LLMMessage array with messages:
    1     User         Text         "Perform my favorite task by using my favorite skill."
    2     Assistant    Tool Call    "loadSkill({"name":"my-favorite-skill"})"
    3     Tool         Text         "# My Favorite Skill  This is the text at the start of my fav..."
    4     Assistant    Text         "This is the agent's response."
```

If the agent has loaded the skill, then the message history contains a tool call to the `loadSkill` function and a tool response that contains the text of the skill. Whether an agent loads a skill depends on the underlying model, as well as the name and description of the skill. To ensure that an agent reads a skill, load the skill manually by using the `loadSkill` function.

### Manually Load Skill
<a id="manually-load-skill"></a>

Instead of relying on the agent to load a skill, manually load the
`"my-second-favorite-skill"` skill into the agent from the previous
example by using the `loadSkill` function.

```
loadSkill(agent,"my-second-favorite-skill");
```

View the new messages in the message history.

```
agent.Messages(5:end)
```

```
ans =

  1×2 LLMMessage array with messages:

    1    Assistant    Tool Call    "loadSkill({"name":"my-second-favorite-skill"})"
    2    Tool         Text         "# My Second Favorite Skill  This is the text at the start of..."
```
### Manually Load Skill Resource
<a id="manually-load-skill-resource"></a>

Some skills have additional resources, such as reference files. Manually load the resources
corresponding to the `"my-favorite-skill"` skill into the same
agent.

```
loadSkill(agent,"my-favorite-skill/references/my-supplemental-information.md");
```

View the new messages in the message history.

```
agent.Messages(7:end)
```

```
ans =

  1×2 LLMMessage array with messages:

    1    Assistant    Tool Call    "loadSkill({"name":"my-favorite-skill/references/my-supplemen..."
    2    Tool         Text         "# Supplemental Information  This is some supplemental inform..."
```
## Input Arguments
<a id="input-arguments"></a>
### `agent` — AI agent
<a id="agent"></a>

`aisdk.AIAgent` object

AI agent, specified as an [`aisdk.AIAgent`](aisdk.AIAgent.md) object.
### `skill` — Skill name
<a id="skill"></a>

string scalar

Skill name, specified as a string scalar.

To see the skills that are available for loading, inspect the
`Skills` property of the agent. To give the agent access to skills,
set the `SkillDirectories` property during or after
construction.

Example: `"my-skill"`

Data Types: `string`
### `skillResource` — Skill resource path
<a id="skillresource"></a>

string scalar

Skill resource path, specified as a string scalar.

Specify the skill resource path starting with the name of the directory that
corresponds to the skill. For example, if you have
this file structure:

```
my-skill-directory/
  my-first-group-of-skills/
    my-favorite-skill/
      SKILL.md
      references/
        my-supplemental-information.md
    my-second-favorite-skill/
      SKILL.md
```

Then you can specify the
`SkillDirectories` property as either
`"my-skill-directory"` or as
`"my-skill-directory/my-first-group-of-skills"`. In either case, to
load the supplemental information corresponding to the
`my-favorite-skill` skill, specify `skillResource`
as `"my-skill/references/supplemental-information.md"`.

Example: `"my-skill/references/supplemental-information.md"`

Data Types: `string`
## See Also
<a id="see-also"></a>

[`aisdk.AIAgent`](aisdk.AIAgent.md)

*Copyright 2026 The MathWorks, Inc.*

