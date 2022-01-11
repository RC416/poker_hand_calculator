module hand_rank_function
export hand_rank_main, hand_rank

### Preamble

# functions used by the main routine (hand_compare_routine.jl) to calculate win probabilities
# preamble and inline comments include details about methodology.


#=
 calculate the "first difference" array by shifting index by 1 and substracting

 ex. hand = [2,3,6,7,9,12,14]
   [2,3,6,7, 9,12,14]
 [2,3,6,7,9,12,14]    -
 ---------------------------
 = [1,3,1,2, 3,2]

 the appearance of combinations of 0s or 1s indicates certain hands:

 [1,1,1,1] => straight
 [0]       => pair
 [0,0]     => 3 of a kind
 [0,0,0]   => 4 of a kind
 [0] in 2 places => 2 pairs

 [2,3,4,5,6,8,11] => [1,1,1,1,2,3] => straight
=#


# Set of all "first differences" sequences that correspond to a straight
# [1,1,1,1] will be most common, but note the possibility of pairs of middle cards
# write them out to avoid re-computing with each call
straight_fds = [

[1,1,1,1],

[1,0,1,1,1],
[1,1,0,1,1],
[1,1,1,0,1],

[1,0,0,1,1,1],
[1,0,1,0,1,1],
[1,0,1,1,0,1],

[1,1,0,0,1,1],
[1,1,0,1,0,1],

[1,1,1,0,0,1],
]

#=
determining value of high card and tiebreaker; score according to card values

score formula gives 2 "digits" to each card from highest to lowest
need to allocate 2 digits to account for the fact that there are 14 values (>10)
ex. [2, 3, 4, 5, 7, 8, 9] scores: 0.09080705040302 = 0.09 08 07 06 05 04 03 02
ex. [2, 3, 4, 5, 7, 11, 15] scores: 0.15110705040302 = 0.15 11 07 05 04 03 02

similarly for higher hands where 
the first digit is the hand strength (0,1,2,...,8) for (no pair, 1 pair, 2 pair, ..., straight flush)
1 pair: value of paired card makes up first digit: [2,2,3,4,7,8,9] = 1. 02 03 04 07 08 09
2 pair: paired cards make up firsth 2 digits: [2,2,3,3,5,7,9] = 2. 03 02 05 07 09
straight: only need highest card: [6,7,8,9,10,11,12] = 4.12
flush: value of highest 5 flush cards: [2,5,6,9,10,13,14] = 5. 14 13 10 09 06
and so on
=#


# composite type (object) stores card number (2-14) and suit (1-4)
struct Card
    number::Int
    suit::Int
end

# for example, the two of hearts is represented as: Two_of_Hearts = Card(2,1)
# can access the number of suit: Two_of_Hearts.number returns 2, Two_of_Hearts.suit returns 1


### Helper functions for main scoring function

# --------------------------------------------------------------------------------------------------
# A. checks if sequence (vector) X is found in sequence (vector) Y in the specific order of X
# returns the index (indices) of the end of the overlap (end of straight, flush, etc,)


function sequence_in_set(X, Y)

    seq_length = length(X)

    # empty array to store any indeces where X overlaps Y
    sequence_match = fill(0, 1)

    # check "sliding window" of Y of length seq_length. (subsets that don't drop interior elements)
    # ex. Y=[1,2,3,4], length(X)=3, check: [1,2,3], [2,3,4].
    # for X=[2,3,4], return index 4. 
    # for X=[1,1,3], return (index) 0. There is no index 0, so no match.

    for n in 1:(length(Y)-length(X)+1)
        # if X matches a subset of Y
        if X == Y[n:n+seq_length-1]
            # save where they overlap, by the largest index of overlap
            push!(sequence_match, n+seq_length) 
        end
    end
    
    # if there were any matches, drop the 0 index
    if maximum(sequence_match) > 0
        deleteat!(sequence_match, 1)
    end

    # return 0 (no match), or list of indeces where there is match
    return sequence_match
end


# B. function to check if vector of cards contains a flush and return corresponding indices
# returns the index of all flush cards, not just the largest
function get_flush_indices(cards)
    # get suit of each card
    suits = [card.suit for card in cards]

    # counts of each suit
    counts = [count(==(suit), suits) for suit in 1:4]

    # check if there is at least 5 of 1 suit
    if maximum(counts) >= 5

        # flush suit
        flush_suit = argmax(counts)

        # return indices of cards in flush
        flush_index = findall(==(flush_suit), suits)

        return flush_index
    else
        # if there is no flush, still reutrn Vector{Int64} but with 0 as only element
        return [0]
    end
end



# C. Main hand scoring function 
# input: 7 card objects (board + starting hand)
# output: score (float)

function hand_rank(cards)

# store final score of hand
hand_score = 0.0

# sort cards by their value
cards = sort!(cards, by = f(card) = card.number) # returns list of 7 card objects sorted by card number/value

# calculate "first differences" vector as described in preamble
first_difference = [cards[n+1].number - cards[n].number for n in 1:6]

# get the locations of pairs, straights and flushes
# use these to check and score hands
pairs_index = sequence_in_set([0], first_difference)
three_of_kind_index = sequence_in_set([0,0], first_difference)
four_of_kind_index = sequence_in_set([0,0,0], first_difference)

straight_index = maximum(sequence_in_set.(straight_fds, Ref(first_difference)))
flush_indices = get_flush_indices(cards)


### 1. check for straight flush
if (flush_indices[1] != 0) & (straight_index[1] != 0) # if you have flush & straight

    # get cards that make up flush
    flush_cards = cards[flush_indices]

    # calculate the first differences for only flush cards
    flush_first_difference = [flush_cards[n+1].number - flush_cards[n].number for n in 1:length(flush_cards)-1]

    # check if a straight sequence exists
    straight_flush_index = maximum(sequence_in_set.(straight_fds, Ref(flush_first_difference)))

    # if a straight flush exists
    if straight_flush_index[1] > 0
        
        # add score of straight flush
        hand_score += 8.0

        # get highest flush card
        high_card = maximum([card.number for card in flush_cards[straight_flush_index]])

        # add tiebreaker score for size of straight: + 0.05-0.15 for value of straight
        hand_score += high_card / 100

        # return score and terminate
        return hand_score
    end
end


### 2. check for 4-of-a-kind
if four_of_kind_index[1] != 0

    # add score of 4-of-a-kind
    hand_score += 7.0

    # get value of card that makes up the 4-of-a-kind
    quad_card = maximum([cards[ind].number for ind in four_of_kind_index])

    # get value of highest single card
    high_card = maximum([card.number for card in cards if card.number != quad_card])

    # calculate tiebreaker score
    hand_score += quad_card/100 + high_card/10000

    # return score and terminate
    return hand_score
end


### 3. check for full house
if (three_of_kind_index[1] != 0)  &  (length(pairs_index) > 2)

    # add score for full house
    hand_score += 6.0

    # get value of card that makes up largest 3-of-a-kind
    trip_card = maximum([cards[ind].number for ind in three_of_kind_index])

    # get largest pair (that is not part of the 3-of-a-kind)
    high_pair = maximum([cards[ind].number for ind in pairs_index if cards[ind].number != trip_card])

    # calculate tiebreaker score
    hand_score += trip_card / 100 + high_pair / 10000

    # return score and terminate
    return hand_score 
end


### 4. check for flush
if flush_indices[1] != 0

    # add score for flush
    hand_score += 5.0

    # get values of cards that make up flush
    flush_cards = cards[flush_indices]
    
    # add tiebreaker score for 5 largest cards
    for n in 0:4
        hand_score += flush_cards[lastindex(flush_cards) - n].number / 10^(2*(n+1))
    end

    # return score and terminate
    return hand_score
end


### 5. check for straight
if straight_index[1] != 0

    # add score for straight
    hand_score += 4.0

    # get highest straight card
    high_card = maximum([card.number for card in cards[straight_index]])

    # add tiebreaker score for size of straight: + 0.05-0.15 for value of straight
    hand_score += high_card / 100.0

    # return score and terminate
    return hand_score
end


### 6. check for 3 of a kind
if three_of_kind_index[1] > 0

    # add score for 3 of a kind
    hand_score += 3.0

    # get score of card that makes up 3-of-a-kind
    trip_card = maximum([cards[ind].number for ind in three_of_kind_index])

    # add tiebreaker score for trip card
    hand_score += trip_card / 100

    # get value for high cards
    high_cards = [card.number for card in cards if card.number != trip_card]

    # add tiebreaker score for 2 single high cards
    hand_score += high_cards[lastindex(high_cards)]/10000 + high_cards[lastindex(high_cards)-1]/1000000

    # return score and terminate
    return hand_score
end


### 7. check for 2-pair
if length(pairs_index) > 1

    # add score for 2-pair
    hand_score += 2.0

    # get value of largest paired cards
    pair_values = [card.number for card in cards[pairs_index]]
    pair_values = pair_values[lastindex(pair_values)-1:lastindex(pair_values)] # keep only last two, largest pairs

    # get value of highest single card
    high_card = maximum([card.number for card in cards if !(card.number in pair_values)])

    # add tiebreaker score
    hand_score += pair_values[2]/100 + pair_values[1]/10000 + high_card/1000000

    # return score and terminate
    return hand_score
end


### 8. check for 1-pair
if pairs_index[1] > 0

    # add score for 1 pair
    hand_score += 1.0

    # get value of paired card
    pair_value = cards[pairs_index][1].number

    # add value of pair to tiebreaker score
    hand_score += pair_value/100

    # get value of unpaired cards
    high_cards = [card.number for card in cards if card.number != pair_value]

    # add value of 3 highest cards to tiebreaker score
    for n in 0:2
        hand_score += high_cards[5-n] / 10^(2*n + 4)
    end

    # return score and terminate
    return hand_score 
end


### 9. if no made hand, assign value for high-card hand
for n in 0:4
    hand_score += cards[7-n].number / 10^(2*n + 2)
end

# return hand score and terminate
return hand_score
end



# Wrapper for the main hand_rank function that handles issue with Aces being high or low
# if Aces exist and there is a low straight, re-run score with aces low instead of high
function hand_rank_main(cards)

    # score tracker
    scores = [0.0]

    # score with aces high
    push!(scores, hand_rank(cards))

    # if there is possibility of low straight, calculate score with aces low
    #if [2,3,4,5] ⊆ [card.number for card in cards]

    card_numbers = [card.number for card in cards]

    # if there is both an ace and a low straight, re-run with aces low
    if (14 in card_numbers) & (issubset([2,3,4,5], card_numbers))

        aces_low_hand = []

        # build new hand with aces low
        for card in cards
            # not an ace, add card unchanged
            if card.number != 14
                push!(aces_low_hand, card)
            end
            # if card is an ace, add as 1 with same suit
            if card.number == 14
                push!(aces_low_hand, Card(1, card.suit))
            end
        end

        # add score for aces low hand to hand score
        push!(scores, hand_rank(aces_low_hand))
    end

    # return score of highest scoring hand
    return maximum(scores)

end 

end # end modeule
