#=
Main routine to calculate hand win probabilities. 
Relies on functions in hand_rank_function.jl. 

Key Steps 
1. pick 2 hands
2. initialize deck of remaining 48 cards
3. create collection of all 5 card subets of deck
4. for each 5 card hand, record which starting hand wins
5. return frequency at which each hand won

definitions:
  card = object with number (2-14) and suit (1-4)
  deck = vector of the remaining (48) unique cards
  boards = all possible 5-card subets of deck
=#


# composite type (object) stores card number (2-14) and suit (1-4)
struct Card
    number::Int
    suit::Int
end



# import key functions and packages
using IterTools # subset function
using Statistics # mean function
using InvertedIndices # not() array indexer

# custom functions from other file. relies on above packages.
cd("C:\\Users\\Ray\\OneDrive\\Projects\\Poker hand calculator")
include("(1) hand_rank_function.jl")
using .hand_rank_function


# cheeky hand abbreviations
A = 14 # ace
K = 13 # king
Q = 12 # queen
J = 11 # jack 
H = ♡ = 1  # hearts
D = ♢ = 2  # diamonds
S = ♠ = 3  # spades
C = ♣ = 4  # clubs

# 1. starting hands
hand_1 = [Card(A,♢), Card(3,♢)]
hand_2 = [Card(J,♠), Card(8,♣)]


# 2. build the deck of remaining cards
deck = fill(Card(0,0), 52) # deck of 52 placeholder hards

# loop through all number and suit combinations and add real cards to deck
card_number = 1

for number in 2:14
    for suit in 1:4
        # add card to deck 
        deck[card_number] = Card(number, suit)
        card_number += 1
    end
end

#= 
# alternative cheeky Julia syntax
for number in [2:10,J,Q,K,A]
    for suit in [♡,♢,♠,♣]
        # add card to deck 
        deck[card_number] = Card(number, suit)
        card_number += 1
    end
end
=#

# remove cards in hand from deck
# helper function for filter!() checks if card is in the hand
function in_hand(card, hands)
    if (card in collect(hands))
        return false
    else
        return true
    end
end

# temporary function initialized with given hands
in_hand(card) = in_hand(card, [hand_1; hand_2])

# remove hand cards from deck
filter!(in_hand, deck)


# 3. build all possible 5-card boards
boards = collect(subsets(deck, 5))

# 4. track who wins
h1_wins = fill(0, length(boards)) # placeholder vectors to track wins
h2_wins = fill(0, length(boards))


# loop over all boards and tabulate which hand wins
#for b in 1:lastindex(boards)
Threads.@threads for b in 1:lastindex(boards) # Threads to run loop on all CPU cores.

    # get score of each hand for given board of 5 cards
    h1_score = hand_rank_main([hand_1; boards[b]])
    h2_score = hand_rank_main([hand_2; boards[b]])

    # record which hand won
    if h1_score > h2_score
        h1_wins[b] = 1
    end

    if h2_score > h1_score
        h2_wins[b] = 1
    end
end


# 5. get results
h1_win_percent = mean(h1_wins)
h2_win_percent = mean(h2_wins)
tie_percent = 1.00 - h1_win_percent - h2_win_percent

# speed testing results
# version 1 (no handling for aces) 18 seconds, 48 card deck, no ace in starting
# version 2 (with handling for aces) 30 seconds, 48 card deck, no ace in starting hand
# version 3 (using parallel processing) 40 seconds, 48 card deck, with ace in starting hand
# version 4 (parallel, better aces handling) 15 seconds, 48 card deck, with ace in starting hand
# version 4 (parallel, better aces handling) 13 seconds, 48 card deck, no ace in starting hand



# profiling/benchmarking
function L(boards)
    for b in 1:lastindex(boards) # Threads to run loop on all CPU cores.

        # get score of each hand for given board of 5 cards
        h1_score = hand_rank_main([hand_1; boards[b]])
        h2_score = hand_rank_main([hand_2; boards[b]])
    
        # record which hand won
        if h1_score > h2_score
            h1_wins[b] = 1
        end
    
        if h2_score > h1_score
            h2_wins[b] = 1
        end
    end
end

using Profile
@profview L(boards)

using BenchmarkTools
@btime L(boards)