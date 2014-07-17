# Read a text file with the following format
# numjobs
# weight length
# weight length
# ...
# return an array with (weight, length) tuples
function read_jobs(fname)
    f = open(fname)
    line = readline(f)
    numjobs = int(line)
    a = Array((Int, Int), numjobs)
    for i in 1:numjobs
        # tuple is (weight, length)
        line = readline(f)
        a[i] = tuple(map(int, split(line))...)
    end
    return a
end

# return true if weight(x) - length(x) > weight(y) - length(y)
# ties are broken by largest weight
function compare_difference(x, y)
    if x[1] - x[2] > y[1] - y[2] 
        return true
    elseif x[1] - x[2] < y[1] - y[2] 
        return false
    else 
        return x[1] > y[1] 
    end
end

function compare_ratio(x, y)
    return x[1] / x[2] > y[1] / y[2]
end

# is_correct uses the ratio between the weight and the length
# not is_correct uses the difference
function order_jobs(v::Vector{(Int, Int)}, is_correct::Bool)
    if (is_correct) 
        ordered = sort(v, lt=compare_ratio)
    else
        ordered = sort(v, lt=compare_difference)
    end
    return ordered
end

function compute_weighted_sum(v::Vector{(Int, Int)})
    time = 0
    sum = 0
    for x in v
        time += x[2]
        sum += x[1] * time
    end
    return sum
end

function problem1(fname::String, correct::Bool)
    raw_data = read_jobs(fname)
    ordered_jobs = order_jobs(raw_data, correct)
    sum = compute_weighted_sum(ordered_jobs)
    return sum
end

assert(compute_weighted_sum([(3,1), (2,2), (1,3)]) == 15)
assert(problem1("1-1.txt", false) == 11336)
assert(problem1("1-1.txt", true) == 10548)
assert(problem1("1-2.txt", false) == 145924)
assert(problem1("1-2.txt", true) == 138232)
# print("Problem 1: $(problem1("jobs.txt", false))\n")
# print("Problem 2: $(problem1("jobs.txt", true))\n")

function read_edges(fname)
    f = open(fname)
    line = readline(f)
    vertices, edges = tuple(map(int, split(line))...)
    d = Dict{Int, Dict{Int, Int}}()
    # d could be an array -- the graph is connected, so we know every
    # vertex has at least one edge.
    for i in 1:edges
        # tuple is (vertex, vertex, weight)
        line = readline(f)
        v1, v2, weight = tuple(map(int, split(line))...)
        if !haskey(d, v1)
            d[v1] = Dict{Int, Int}()
        end
        
        if !haskey(d, v2)
            d[v2] = Dict{Int, Int}()
        end

        d[v1][v2] = weight
        d[v2][v1] = weight
     end
    return d
end

function compute_mst_naive(g)
    # Assume graph is connected, so we can start with any node.
    not_done = Dict()
    weight = 0
    for k in keys(g)
        not_done[k] = true
    end
    done = {1 => true}
    delete!(not_done, 1)

    while !isempty(not_done)
        existing, new = find_cheapest(done, g)       
        weight += g[existing][new]
        done[new] = true
        delete!(not_done, new)
    end

    return weight
end

function find_cheapest(done, g)
    cost = typemax(Int)
    cheapest = (0, 0)
    for v1 in keys(done)
        for v2 in keys(g[v1])
            if !haskey(done, v2) && g[v1][v2] < cost
                cost = g[v1][v2]
                cheapest = (v1, v2)
            end
        end
    end
    assert(cheapest != (0,0))
    return cheapest
end

g = read_edges("1-3.txt")
assert(compute_mst_naive(g) == 2624)

# g = read_edges("edges.txt")
# print("Problem 3: $(compute_mst_naive(g))\n")

function read_clusters(fname::String)
    f = open(fname)
    line = readline(f)
    num_vertices = int(line)
    a = Array((Int, Int, Int), 0)    

    line = readline(f)
    while line != ""
        # tuple is (vertex, vertex, weight)
        push!(a, tuple(map(int, split(line))...))       
        line = readline(f)
    end
    return (a, num_vertices)
end

function read_clusters_binary(fname::String)
    f = open(fname)
    line = readline(f)
    num_vertices, num_bits = tuple(map(int, split(line))...)
    d = Dict{Int, Bool}()

    line = readline(f)
    while line != ""
        num = 0
        line = chomp(line)
        for c in line
            if c != ' '
                num = (num << 1) | parseint(c)
            end
        end
        d[num] = true

        line = readline(f)
    end   
    return d
end

function clustering_compare_edges(x, y)
    return x[3] < y[3]
end

function sort_by_edge_weight(v::Vector{(Int, Int, Int)})
    # put smallest edges on top
    sort(v, lt=clustering_compare_edges)
end

include("union-find.jl")

function find_cluster_distance(fname::String)
    unsorted_edges, num_vertices = read_clusters(fname)
    sorted_edges = sort_by_edge_weight(unsorted_edges)
    u = make_union(num_vertices)
    done = false
    for (v1, v2, distance) in sorted_edges
        if length(u) <= 4
            done = true
        end
        
        if find(u, v1) != find(u, v2)
            if !done
                union(u, find(u, v1), find(u, v2))
            else
                return distance
                break
            end
        end
    end
end

function single_bits(num_bits::Int)
    max_shift = num_bits - 1
    d = Dict{Int, Bool}()
    for i in 0:max_shift
        d[1 << i] = true
    end
    return d
end

function double_bits(num_bits::Int)
    # this gets single and double bits.
    max_shift = num_bits - 1
    d = Dict{Int, Bool}()
    bits = single_bits(num_bits)
    for x in keys(bits)
        for y in keys(bits)
            d[x | y] = true
        end
    end
    return d
end

function find_num_big_clusters()
#    vertices = read_clusters_binary("clustering_small.txt")
    vertices = read_clusters_binary("clustering_big.txt")
    u = UF(Dict{Int, Int}(), Dict{Int, Vector{Int}}())

    # make a hash of all vertices
    for v in keys(vertices)
        push!(u, v)
    end
    print("Read in vertices\n")

    # generate all double bit pairs up to length 24
    all_bits = double_bits(24)
    
    print("Generated $(length(all_bits)) bit pairs\n")
    # create clusters for everything within hamming distance 2
    for v1 in keys(vertices)
        for b in keys(all_bits)
            v2 = v1 $ b
            if haskey(vertices, v2)
                union(u, find(u, v1), find(u, v2))
            end
        end
    end

    return length(u)
end

assert(find_cluster_distance("3-1-a.txt")==134365)
assert(find_cluster_distance("3-1-b.txt")==7)
# print(find_cluster_distance("clustering1.txt"))
# print(read_clusters_binary("clustering_small.txt"))
# print(find_num_big_clusters())

function max_knapsack_value(fname::String)
    # Note that we don't have a weight = 0 dimension in the array to work around
    # julia's 1 indexed arrays without kluding up every array access. This should
    # be fine except for degenerate cases.

    function read_items(fname::String)
        f = open(fname)
        line = readline(f)
        capacity, num_items = tuple(map(int, split(line))...)
        a = Array((Int, Int), num_items)

        max_weight = 0
        for i in 1:num_items
            # tuple is (value, weight)
            line = readline(f)
            value, weight = tuple(map(int, split(line))...)
            if weight > max_weight
                max_weight = weight
            end
            a[i] = (value, weight)
        end
        return (a, capacity, max_weight)
    end

    function max_without_item(a, i, j)
        # this would be more effficient if we made the array one larger and avoided
        # this branch all the time, but julia's 1-indexing makes that less readable.
        if i-1 > 0
            return a[i-1, j]
        else
            return 0
        end
    end

    function max_with_item(a, i, j, value, weight)
        # nonsense function to deal with julia's 1-based arrays
        if i-1 < 1 && j-weight >= 0 || j-weight == 0
            return value 
        elseif j-weight < 1 || i-1 < 1
            return 0
        else
            return a[i-1, j-weight] + value
        end
    end

    all_items, capacity, max_weight = read_items(fname)

    a = Array(Int, length(all_items), capacity)

    for i in 1:length(all_items)
        for j in 1:capacity
            value, weight = all_items[i]
            a[i, j] = max_without_item(a, i, j) > max_with_item(a, i, j, value, weight) ?
            max_without_item(a, i, j) : max_with_item(a, i, j, value, weight)
        end
    end

    return a[length(all_items), capacity]
end

assert(max_knapsack_value("knapsack-test-1.txt") == 60)
assert(max_knapsack_value("knapsack-test-1b.txt") == 60)
assert(max_knapsack_value("knapsack-test-1c.txt") == 60)
assert(max_knapsack_value("knapsack-test-2.txt") == 2700)
assert(max_knapsack_value("knapsack-test-2b.txt") == 27000)
assert(max_knapsack_value("knapsack-test-2c.txt") == 27000)
print("$(max_knapsack_value("knapsack1.txt"))\n")
print("$(max_knapsack_value("knapsack_big.txt"))\n")
