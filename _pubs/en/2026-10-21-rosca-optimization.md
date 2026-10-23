---
title: "A 'tasty' optimization: ROtating Savings and Credit Associations ('ROSCA's)"
collection: pubs
category: posts
permalink: /pub/2026-10-21-rosca-optimization
excerpt: 'How would you optimize peer-to-peer, interest-free banking?'
date: 2026-10-21
lang: en
---

Consider 10 people, each beginning with an empty balance (0€), earning 1000€ per month and wishing to buy a 10000€ car. Additionally assume no interest-based loans or payment plans are available, such that there are no options to finance the purchase over time.

Goals like the cars in this scenario imply a threshold: either a person has the total 10000€ available, or no car can be purchased. There is no concept here of, for instance, keep paying 1000€ for "a tenth of a car" to eventually combine 10 of those "tenths" into a single car: it is not a continuous purchase but a discrete one, imposing a cost threshold that must be reached.

Under regular circumstances, each person would just save their own monthly earnings, and all 10 people would be able to buy a car after 10 months. If, for each person, we consider the time taken to buy their goal as a metric, this results in an aggregated 100 months of total wait time.

However, a [Rotating Savings and Credit Association ('ROSCA')](https://en.wikipedia.org/wiki/Rotating_savings_and_credit_association){:target="_blank"} can alleviate this by combining small earnings of its members and reaching goal quantities faster. Consider a typical 'ROSCA' structure, where each round (assume a monthly member reunion) all members deposit an agreed amount of money in the common fund (for instance, a fraction of their monthly salary) and a single person takes it all, a different person each round. The first person would reach 10000€ and buy the car the very first month (1 month of wait time). Then, another person the next month (2 months of wait time), the next person would wait 3 months, and so on, until the last person in the designated rotatory order would reach the goal after 10 months. This, therefore, results in a total of $$1+2+\dots+10 = 55$$ month aggregated wait time, clearly better than individual saving. No interests were involved, no external money entered the structure other than the monthly member earnings, yet a proper aggregation of money managed to collectively reach the purchase thresholds in an overall quicker wait time.

> Note: this "mathematical" benefit of partaking in 'ROSCA's is not their only benefit. For instance, there can also be a psychological benefit akin to a bank deposit, where periodically earned money being lent to the common fund (and not staying in your hands) is a way to prevent temptations of spending it.

However, is the described scheme truly optimal? For instance, what if two people took half the total each round, instead of a single person taking it all? What about unequal scenarios, with different initial balances, different earnings and/or different purchase goals? Is such a simple strategy the best one?

- [Getting optimal](#getting-optimal)
  - [Are you a MILP lover?](#are-you-a-milp-lover)
- [From math to code](#from-math-to-code)
  - [Wait... are we overcomplicating things?](#wait-are-we-overcomplicating-things)
- [Results](#results)
  - [Uniform case](#uniform-case)
  - ["One-different" case](#one-different-case)
  - [Random case](#random-case)
  - [MILP can get quite expensive](#milp-can-get-quite-expensive)
- [Conclusions and future work](#conclusions-and-future-work)

## Getting optimal

If you stumble upon a situation where you have a certain quantity to minimize or maximize, as well as a bunch of constraints that must be satisfied, you have an optimization problem in front of you. These can be quite ordinary: say you want to pack as many items as you can in your backpack, giving them some sort of priority depending on how much you value each item type (you might make it kind-of quantitative by picking a 1-10 priority scale or something similar) yet you cannot exceed the backpack's volume, and you need to make sure you won't hurt yourself by making the backpack too heavy. This example is, in fact, a very well known optimization problem known as the [knapsack problem](https://en.wikipedia.org/wiki/Knapsack_problem){:target="_blank"}: you wish to maximize the "value" inside the backpack, subject to volume and weight limitations.

In order to mathematically state such problems, so that you can solve them numerically with dedicated software or libraries, you need to pick variables for the "unknowns" of your problem that you want to fine-tune to maximize/minimize your goal: in the backpack case, this would be the quantity of each item type to bring with you. This choice is not mere naming, as it shows the true nature of the problem. If your variables reflect, for instance, money or distances, they probably are *continuous*: they can be any real number in principle, perhaps constrained by lower/upper-bounds. Meanwhile, if they are amounts of indivisible objects (say one, two, ten apples) or binary indicators (1/0 as in true/false) then they are *discrete*, taking only integer values.

The dependency of the variables on the quantity to maximize/minimize and the constraints is also highly relevant. In the backpack example, you can express either the total value, total volume or total weight as linear combinations of the integer variables $$x_i$$ of the amounts of each item you're taking. For instance, the total value would be $$V = v_1 x_1 + v_2 x_2 + \dots + v_n x_n$$, given that you are considering $$n$$ item categories, where a single item of category $$i$$ has value $$v_i$$.

This is not a mere coincidence, as it's typical to end up with quantities that are *linear* dependencies on the problem variables. Other less-frequent problems might require *quadratic* dependencies (products of two variables: $$x_1 \cdot x_2 + \dots$$) or maybe even more complicated things. I'll give later a few hints at the impact that these two aspects (nature of variables and type of objective/constraints) have on whether the optimization resolution is fairly easy or notoriously hard to carry out.
 
> Note: considering that total volume and total weight are also directly additive in the backpack example is, well, a somewhat crude simplification. If we get more technical, volume is a spatial property and requires addressing which space is occupied by which item, and the weight is affected by the spatial packing of items in the backpack... in other words, these are not as trivial as adding "raw" weights and volumes, although this serves as a reasonable approximation in many cases. Give a read at [bin packaging problems](https://en.wikipedia.org/wiki/Bin_packing_problem){:target="_blank"} for optimizations where these aspects are considered in a less crude way (of course, at the expense of a more complicated formulation of the optimization problem!).

As you may be thinking by this point, the specifics of a particular 'ROSCA' configuration can be studied as an optimization problem. Let's attempt to formulate it.

A group of $$N$$ people decide to periodically deposit and take money from a common fund. The process involves a total of $$T$$ time-steps ($$t = 0 \dots T-1$$). The $$i$$-th person ($$i = 0 \dots N-1$$) earns a quantity $$w_i$$ each time-step (say, as their wages or a fraction of them) and their goal is to eventually reach a goal quantity $$g_i$$ in their personal balance. Once the goal is reached, the person inmediately purchases it, deducting $$g_i$$ from their balance. The common fund begins with $$B_{init}$$ and each person initially has $$p_{i,init}$$ on their balance.

Each time-step $$t$$, each person $$i$$ earns $$w_i$$ and also takes $$\Delta p_{it}$$ from the common fund. These quantities $$\Delta p_{it}$$ combine both the money deposited first in the common fund, and then taken afterwards (they may be positive, zero or negative) and characterize the dynamics of the considered 'ROSCA'. For instance, I'd encourage you to verify that the default, conventional 'ROSCA' introduced before, assuming that the "selected" person at time $$t$$ is the person $$r_t$$ (following the rotatory order agreed beforehand), corresponds to these dynamics:

$$
\Delta p_{it} = - w_i + \delta_{i, r_t} \sum_j{w_j}
$$

> Note: $$\delta_{ij}$$ is the [Kronecker delta](https://en.wikipedia.org/wiki/Kronecker_delta){:target="_blank"}, whose value is 1 if $$i = j$$ and 0 otherwise. It is a particularly convenient notation for expressing conditional values and quantities without the need of braces nor branches.

If we denote the balance of person $$i$$ at time-step $$t$$ as $$p_{it}$$, at the time-step in which the person manages to earn enough money for their goal (the first time-step $$t$$ where $$p_{it} \ge g_i$$), the goal amount is inmediately subtracted from their balance.

As previously motivated, our objective is to minimize the total (aggregated) wait time, consisting of the sum of each person's wait time (the time-step when the person's balance reaches enough to purchase their goal).

### Are you a MILP lover?

Since continuous quantities (money) are involved, my first idea was to formulate the problem as a [**Linear Programming** problem](https://en.wikipedia.org/wiki/Linear_programming){:target="_blank"} (**LP**): this is a family of optimization problems (probably the most famous one) where all problem variables are continuous and where both the objective and the problem constraints (which, by the way, are expressed as equalities or inequalities) are all linear combinations of the problem variables. 

This is also a rather natural choice because many of the relationships mentioned in the previous section are themselves linear. The clear candidate for problem variables are the balance variations $$\Delta p_{it}$$, since they model how the 'ROSCA' works after all, which can take any real value, positive or negative, subject to certain bounds (a person cannot deposit in the common fund more money than they have on their balance at that moment, for instance).

However, I soon ran into a problem: the goal-purchase, which involves subtracting the purchased amount $$g_i$$ from the person's balance at the time-step in which it was purchased and all future time-steps, is tricky to formulate. Ignoring the purchase, the balance of a person $$i$$ as we move from time-step $$t-1$$ to $$t$$ is straightforward to formulate, resulting in a simple, linear relationship:

$$
p_{it} = p_{i,t-1} + \Delta p_{it} + w_i
$$

In order to reflect the goal purchase, we need to track when the purchase happens, and from that point subtract $$g_i$$. For this reason, I eventually went ahead by introducing a bunch of discrete variables to reflect the purchase, which resulted in a very clean formulation that properly encoded the problem.

However, we now have both discrete and continuous variables: this is now a [**Mixed-Integer Linear Programming** problem](https://en.wikipedia.org/wiki/Integer_programming){:target="_blank"} (**MILP**), a slightly different family of optimization problems. Does this simplify or complicate things? Definitely the latter, but we'll discuss the implications later. Luckily for us, the problem formulation is still fully linear ;)

> Note: the only generative AI usage in this project was a single "exchange" I had with the LLM model `qwen3.8:27b` used locally, where I tried asking it for suggestions on modelling the purchase on my then half-baked formulation (I was a bit lost and curious to test its reasoning), and in which the LLM suggested a rather messy MILP formulation which I did not really like, but whose thought-process gave me the idea of playing around by introducing binary variables.

Let me explicitate the MILP formulation I eventually settled with. First of all, let's clearly distinguish the initial values we know and which characterize the situation of our problem (our inputs) from the other problem variables. These are our inputs:

- Number of people $$N$$

- Simulation length / total time-step count $$T$$

- Initial common fund balance $$B_{init}$$

- Initial balances for each person $$p_{i,init}$$

- Per-time-step earnings of each person $$w_i$$

- Purchase goals per person $$g_i$$

Throughout the formulation I will use the index $$i = 0 \dots N-1$$ to denote people, and the index $$t = 0 \dots T-1$$ to denote each time-step. I chose them to begin at 0 to make it straightforward to implement in code later.

> Note: since the choice of $$T$$ is nontrivial and might cause some goals to never be reached if it's too small, or will waste variables if it's too large, a "reasonable" rule of thumb I followed is to use the largest wait time if the 'ROSCA' was not performed at all (individual savings), as a worst-case scenario, to at least ensure that all goals are satisfied eventually. Such choice of $$T$$ is computed as:
> 
> $$
> T = \max_i{\lceil \frac{g_i - p_{i,init}}{w_i} \rceil}
> $$

These are the problem variables (the "unknowns" we want to solve for to make the problem optimal):

- $$\Delta p_{it}$$ (continuous): amount of money taken/deposited each time-step $$t$$ by person $$i$$
- $$a_{it}$$ (binary, only values 0 and 1): whether person $$i$$ has acquired their goal by time-step $$t$$

Therefore, we will use a total of $$2NT$$ variables: $$NT$$ continuous and $$NT$$ binary.

The MILP formulation is the following: we wish to *maximize* $$\sum_{i,t}{a_{it}}$$

*subject to*

- Common fund evolution:

  $$B_0 = B_{init} - \sum_i{\Delta p_{i0}}$$ (for $$t = 0$$)

  $$B_t = B_{t-1} -  \sum_i{\Delta p_{it}}$$ (for $$t > 0$$)

- No-acquisition per-person balance evolution (per-person balance if the purchase is never done even if the threshold is reached):

  $$p_{i0} = p_{i,init} + \Delta p_{i0} + w_0$$ (for $$t = 0$$)

  $$p_{it} = p_{i,t-1} + \Delta p_{it} + w_i$$ (for $$t > 0$$)

- Real per-person balance evolution:

  $$q_{it} = p_{it} - a_{it} g_i$$

- Binary purchase-done variables can have value 1 only after the goal is reached:

  $$a_{it} \le \frac{p_{it}}{g_i}$$

- Once acquired the goal, all future binary purchase-done variables must encode it (as their definition intends):

  $$a_{it} \ge a_{i,t-1}$$ (for $$t > 0$$)

  > Note: all these $$a_{it}$$ conditions still mean that the variables could be either 0 or 1 when $$p_{it} > g_i$$. In order to really force them to be strictly 1 when the goal is reached, as we want per their definitions, we have to maximize all of them in the objective above.

- Cannot take from the common fund more than what is currently there (debt is not considered in this problem):

  $$B_t \ge 0$$ (for all $$t$$)

- People cannot deposit more than what they have in their current balance + the time-step earnings (debt is not considered in this problem):

  $$p_{i,init} + \Delta p_{i0} + w_i \ge 0$$ (for $$t = 0$$)
  
  $$q_{i,t-1} + \Delta p_{it} + w_i \ge 0$$ (for $$t > 0$$)

Keep in mind that the real balance of a person $$i$$ at time-step $$t$$ is given by $$q_{it}$$, while $$p_{it}$$ is a "ficticious" balance (or rather, the balance if no purchase is ever made even if the goal is reached). Binary variables are essential to model the "sudden drop" due to the purchase, and still result in linear relationships since the $$g_i$$ quantities are per-person input constants.

There is one subtlety you may be confused about: why would maximizing the sum of all binary purchase-done variables (which is required due to their nature and for no other reason!) result in the desired total wait time optimization? After all, we really aim to minimize $$\sum_i{\tau_i}$$, where $$\tau_i$$ is the wait time of person $$i$$ (the time-step where they reach the goal amount and make the purchase), so why would this formulation correspond to such an optimization?

Well, this formulation has a really nice property (that I took a while to notice): the sum of all binary purchase-done variables $$a_{it}$$ for a given person satisfies the relationship

$$
\tau_i + \sum_t{a_{it}} = T \quad \forall i
$$

Intuitively speaking, this happens because $$\tau_i$$ represents the elapsed time-step count prior to the purchase, and the sum of binary purchase-done variables is precisely counting the elapsed time-steps after the purchase (and including the one when the purchase is done), such that together they cover all the simulated time-steps $$T$$.

Now, two key properties of optimization come into play. First of all, aiming to minimize some quantity $$C$$ (think of it as a cost) is mathematically equivalent to aiming to maximize $$-C$$ (I think it's rather easy to see why). Secondly, if $$C(x_i \dots)$$ is some cost that depends on the problem variables $$x_i$$ and $$c$$ is some numerical constant, minimizing $$C(x_i \dots) + c$$ is equivalent to just minimizing $$C(x_i \dots)$$: in other words, adding or subtracting constants to the quantity you aim to minimize/maximize does not change the optimization problem at all (you are just shifting the objective by a fixed amount, independent of any problem variables).

Taking the "fortunate" relationship above and summing over $$i$$ we can see that

$$
\sum_i{\tau_i} = NT - \sum_{i,t}{a_{it}} = \text{const} - \sum_{i,t}{a_{it}}
$$

and since $$NT$$ is a constant value, and putting everything together, we see that the all-$$a_{it}$$ maximization is mathematically equivalent to the desired all-$$\tau_i$$ minimization!

I really want to emphasize this again: we were forced to maximize the binary purchase-done variables $$a_{it}$$ in order to enforce them to always be 1 after their corresponding purchase has been done... the fact that this very maximization precisely coincides with the optimization we were looking for is a quite lucky coindidence! This does not align so nicely in most optimization problems, where we would have to consider a combination of two (or maybe more) objectives to maximize, one of them required by the choice of variables (like with our $$a_{it}$$) and the others to really encode the desired optimization.

In other words, this is truly killing two birds with one stone! 

Feel free to stop and think about this formulation until you see how and why it encodes our problem! Let's now take this MILP problem and see how well it performs.

## From math to code

There are many libraries and software tools for implementing and solving optimization problems, but I settled on [PuLP](https://pypi.org/project/PuLP/){:target="_blank"}, a Python library equipped with multiple solvers for multiple problem types. I created [a simple module](https://github.com/XabiF/rosca-optimization/blob/main/rosca.py){:target="_blank"} for the generic resolution of arbitrary 'ROSCA' configurations using the formulation above. The solver routine takes all the inputs mentioned above ($$N$$, $$T$$, $$B_{init}$$ and so on) and outputs the optimal choice for variables $$\Delta p_{it}$$ and $$a_{it}$$, which can be post-processed to extract the actual dynamics of the solved 'ROSCA'.

Here's an example small 'ROSCA' ($$N = 3$$) dynamics obtained from a solver's output:

```
ROSCA SIMULATION
 TIME-STEP t=0:
  Bank currently has 0€
   * Person 0 (currently has 0€) earns 1000€ and takes 2000€ from the bank (now has 3000€)
      Goal of 3000€ reached! Purchased, now has 0€
   - Person 1 (currently has 0€) earns 1000€ and deposits 1000€ in the bank (now has 0€)
   - Person 2 (currently has 0€) earns 1000€ and deposits 1000€ in the bank (now has 0€)
  Bank is left with 0€
 TIME-STEP t=1:
  Bank currently has 0€
   * Person 0 (currently has 0€) earns 1000€ and deposits 1000€ in the bank (now has 0€)
   * Person 1 (currently has 0€) earns 1000€ and takes 2000€ from the bank (now has 3000€)
      Goal of 3000€ reached! Purchased, now has 0€
   - Person 2 (currently has 0€) earns 1000€ and deposits 1000€ in the bank (now has 0€)
  Bank is left with 0€
 TIME-STEP t=2:
  Bank currently has 0€
   * Person 0 (currently has 0€) earns 1000€ and deposits 1000€ in the bank (now has 0€)
   * Person 1 (currently has 0€) earns 1000€ and deposits 1000€ in the bank (now has 0€)
   * Person 2 (currently has 0€) earns 1000€ and takes 2000€ from the bank (now has 3000€)
      Goal of 3000€ reached! Purchased, now has 0€
  Bank is left with 0€
Goal reach wait times: [1, 2, 3], total wait time = 6
```

What 'ROSCA' configurations shall we study? I settled on three different scenarios:

- The 'uniform' scenario: all people begin with an empty balance, the common fund also begins empty, all $$N$$ people earn 1000€ per time-step (I essentially think of them as months throughout the entire implementation) and have a goal of 10000€.

- The 'one-different' scenario: same as the 'uniform' scenario, but a single person has a different goal of 5000€ instead.

- The 'random' scenario: all people begin with random balances between 0€ and 3000€, the common fund begins randomly between 0€ and 1000€, all $$N$$ people earn a fixed random quantity between 800€ and 1600€ per time-step and have a random goal between 8000€ and 16000€. All random quantities are integers sampled uniformly on the mentioned ranges respectively.

I began by making manual, individual tests for some arbitrary $$N$$ values (this was also the phase where I was testing and playing around with MILP formulations after all). When everything worked as expected, I moved into more interesting aspects to study. After all, going back to the starting questions, is the typical 'ROSCA' structure truly a good approach in more complicated situations? 

Another aspect to study were run-times: what about the time our MILP formulation needs to be solved? How does it scale as we increase the problem size (by increasing the number of people $$N$$)?

### Wait... are we overcomplicating things?

While I was finishing with the MILP code and moving on with more testing, I kept thinking if solving such a problem using optimization techniques was, maybe, excessive. Is this problem more trivial than what I initially considered? What if a simple heuristic, maybe a bit more elaborated than the typical 'ROSCA' structure (one that generalizes it) could provide the best results without the need for optimization?

In order to make any meaningful comparisons, I came up with a heuristic-based solver based on the following premise: by allowing people with smaller goals (or rather, smaller goals minus their starting balance, the "effective" goals) to reach it first, we might (perhaps) achieve optimality. This is motivated by the default 'ROSCA's nature: strategies which make people finish as quickly as possible (even if seen from an individual and not an agregated perspective) appear reasonable.

The heuristic-based solver I implemented is rather simple to describe: first of all, people are sorted by their "effective" goals (in ascending order, shorter goals first). Then, one by one, all the money at the following time-steps is allocated to them until they reach their goal. If there is some amount of money in the common fund that the person didn't need to reach their goal in some time-step, then that amount is taken by the next person (so that in this "mixed" time-step one person reaches their goal and the next one begins their "pursuit").

## Results

By this point, we have three "solvers": doing nothing (no 'ROSCA', so people individually save their earnings, clearly the worst case but is useful for comparisons), MILP resolution and the heuristic approach. The first and last cases are blazingly fast (in the heuristic case, it's just a bunch of fast conditionals, for-loops and not much more), so the time-scalability is mostly interesting on the MILP case, since solving optimization problems is nontrivial and can get expensive quickly. Let's see what this models can do!

### Uniform case

For the uniform case, the typical 'ROSCA' structure is indeed optimal!

This can be intuitively reasoned. Starting from this optimal, one-person-takes-it-all 'ROSCA' structure, consider "splitting" it, such that each time-step two people take half of all deposited money each in the common fund. None of them will be able to reach their goal in 1 month (they each only have 5000€), and they will both reach it in 2 months for a total 4 months of wait time. Meanwhile, in the original structure, one of them reaches it in 1 month and the other one in 2 months, totalling 3 months of wait time. The point to be generalized here is that any such "splittings" (any deviations from the one-person-takes-it-all configuration) result in longer wait times for some people. There probably are better insights into this optimality on the uniform case! I encourage you to give it a thought, maybe even mathematically proof the optimality.

This plot shows the found solutions (where the solution quality, as mentioned, is a measure of the total wait time) for each solver and for different people $$N$$:

<div style="text-align: center;">
<img src="/images/pubs/rosca-optimization/plot_3to11_wait_times_uniform.png" alt="drawing" width="75%"/>
</div>

You won't be able to distinguish the 'heuristic' and 'MILP' tendencies, because they overlap! Indeed, for the (trivial) uniform case, the MILP resolution, the heuristic based resolution and typical 'ROSCA' one-takes-it-all rotatory structure result all in the same optimal solutions. This approach is, of course, better than doing no 'ROSCA' at all (as already illustrated at the start of this post). In fact, the difference becomes greater as we consider scenarios with more people.

### "One-different" case

Regarding the one-different case, we get similar results:

<div style="text-align: center;">
<img src="/images/pubs/rosca-optimization/plot_3to11_wait_times_one-different.png" alt="drawing" width="75%"/>
</div>

We only made a single person different, and by a neat fraction of the changed goal, so not much changes. The typical 'ROSCA' architecture would still work optimally.

### Random case

The random case is the most interesting one, as different values on the people involved create less trivial configurations:

<div style="text-align: center;">
<img src="/images/pubs/rosca-optimization/plot_3to11_wait_times_random.png" alt="drawing" width="75%"/>
</div>

Well, look at that! MILP does indeed beat the heuristic model under less trivial circumstances, even though their solutions are relatively close to each other (compared to the do-nothing scenarios).

This wonderfully showcases the nature of heuristic solvers: they can solve certain "less nontrivial" configurations blazingly fast and achieve optimality or get really close to it, yet as the problem gets more complicated and if you consider more nontrivial configurations, its solutions clearly become suboptimal. Optimization-based solvers explore a larger amount of possibilities, but as they are more complicated solving techniques, they are not as fast as simple conditionals and for-loop logic.

Note that suboptimal results are not inherently bad, at least if they are ""close enough"" to optimality. We have two key factors to judge the two nontrivial solvers: time and optimality. There are real-life situations where a stupid fast and suboptimal, close-to-optimal solver is more desirable than a perfectly optimal yet slower one. Meanwhile, in other use-cases, the opposite might be true: even if it takes a long time, you really need the solution to be truly optimal.

In fact, this heuristic can be considered a form of [greedy optimization](https://en.wikipedia.org/wiki/Greedy_algorithm){:target="_blank"}. Think, for instance, of the backpack example we used before, and imagine you divise a strategy where you prioritize putting as many items as you can of the most valuable kind, and once you cannot fit more, you continue with the next "most valuable" kind, until you cannot fit more items of any kind. This might sound reasonable as an approach to solve the problem, but it is not optimal in general! You might get a "good enough" solution if you don't care about true optimality, but heuristics are fundamentally limited because they only consider (by their design) a subset of all the (exponentially many, or maybe even worse) combinations of variables.

### MILP can get quite expensive

You may be wondering why I didn't simulate 'ROSCA's with no more than $$N = 11$$ people. It's not because I didn't want to, but because the MILP solver becomes prohibitely expensive in run-time!

The following plots show the run-time for different $$N$$ for the different cases considered:

<div style="text-align: center;">
<img src="/images/pubs/rosca-optimization/plot_3to11_milp_solve_times_uniform.png" alt="drawing" width="50%"/>
<img src="/images/pubs/rosca-optimization/plot_3to11_milp_solve_times_one-different.png" alt="drawing" width="50%"/>
<img src="/images/pubs/rosca-optimization/plot_3to11_milp_solve_times_random.png" alt="drawing" width="50%"/>
</div>

The individual run-times themselves are not terrible (the worst ones take close to 3min), but since I simulated several runs to get averaged metrics (essentially for the random case), the overall time of the simulation code increases notoriously.

For all the considered cases, even for the simple uniform and one-different cases, the run-time explodes after $$N = 10$$ ($$N = 9$$ in the one-different case). However, note the scales: the random case scales notoriously worse than the rest! This was somewhat expectable, since I precisely chose it to have a highly nontrivial case.

Just for reference, generating [all the plots shown in this post](link a ipynb) up to $$N = 10$$ takes somewhere around 30-40min, and for higher inputs it just gets worse and worse...

The point is clear: this MILP formulation scales quite badly as $$N$$ increases, but why is that? Now we need to get back to discrete vs. coninuous variables and the problem objective and constraints. These last two, in this case, are not problematic (by themselves) since they're all nice and linear.

Linear objectives and constraints, along with continuous variables (a simple LP problem) scale the best (they are efficient most of the times). Continuous variables are nice to deal with, but discrete variables are quite complicated. Algorithms exist to solve integer or mixed problems, of course (how do you think I've been able to solve this MILP problem?), but they scale poorly with system size. For $$N = 10$$ people and, say, $$T = 10$$ time-steps, we are formulating an optimization problem with 100 real and 100 binary variables, which is quite a lot of them!

> Note: more technically, optimization problems need to be convex to be efficiently solved. Linear functions of real variables are both convex and concave, so they are nice to work with. Quadratic functions begin to be problematic, as they can be convex or non-convex depending on their shape. When discrete variables enter the problem, the sheer notion of convexity disappears (since it requires continuity to make sense), so the problems become all non-convex. Several algorithms exist to solve them, but all of them are known to scale badly as the problem size increases.

## Conclusions and future work

This was a short and fun Proof-of-Concept, a small study that caught my curiosity after thinking on the practical utility of this types of "informal", local, interest-free banking systems. Feel free to take a look and play around with my code [in the dedicated repository](https://github.com/XabiF/rosca-optimization){:target="_blank"}!

As is typical with optimization problems, you can complicate them as much as you want.

Want to prioritize some people, say, because their goal is more urgent? You could introduce incentives in the cost function by including per-person weights $$k_i$$ (resulting in $$\sum_{i,t}{k_i a_{it}}$$), or you could impose as a hard constraint that a given goal must be satisfied prior to some time-step $$s$$ by forcing the corresponding binary purchase-done variable (and the ones after) to be 1 ($$a_{is} > 0$$), although this might get tricky and you might end up with infeasible configurations...

There maybe be better ways to formulate and solve this problem as a MILP problem, although I'm pretty sure you would always be forced introduce some form of discrete auxiliary variables that can represent the discrete time-steps and/or the sudden goal-purchase process, like $$a_{it}$$ in this formulation.

Interestingly, Quantum Computing might, perhaps, alleviate the bad MILP scaling of this problem. There is a different family of optimization problems, [QUBO problems](https://en.wikipedia.org/wiki/Quadratic_unconstrained_binary_optimization){:target="_blank"} (careful, the "Q" in QUBO does not stand for "quantum"!) that are formulated in terms of binary variables and happen to be naturally suited to be solved with quantum computers (this is, in fact, what I work in, among other things). Could this problem be formulated as a QUBO problem and be solved more efficiently? I probably should continue with this toy project in that direction...
