defmodule Astar do
  require Astar.HeapMap, [as: HMap]

  @type  vertex     :: any
  @type  nbs_f      :: ((vertex) -> [vertex])
  @type  distance_f :: ((vertex,vertex) -> non_neg_integer)
  @type  env        :: {nbs_f, distance_f, distance_f}


  @doc """
  A* path finding.

  * `env`   - a graph "environment" - the tuple `{nbs, dist, h}` where
    each element is a function:
    * `nbs`   - returns collection of neighbor vertices for a given vertex
    * `dist`  - returns edge cost between two neighbor vertices
    * `h`     - returns estimated cost between two arbitrary vertices
  * `start` - starting vertex
  * `goal`  - vertex we want to reach
  """

  @spec astar(env, vertex, vertex) :: [vertex]

  def astar({_nbs, _dist, h}=env, start, goal) do
    openmap = HMap.new
              |> HMap.add(h.(start,goal), start, 0)

    loop(env, goal, openmap, HashSet.new, HashDict.new)
  end

  @spec loop(env, vertex, HMap.t, Set.t, Dict.t) :: [vertex]

  defp loop({nbs, dist, h}=env, goal, openmap, closedset, parents) do
    if HMap.empty?(openmap) do []
    else
      {_fx, x, openmap} = HMap.pop(openmap)
      if x == goal do
        cons_path(parents, goal)
      else

        closedset = Set.put(closedset, x)

        {openmap,parents} = Enum.reduce nbs.(x), {openmap,parents},
        fn(y, {openmap,parents}=continue) ->

          if Set.member?(closedset, y) do continue
          else
            est_g = HMap.get_by_key(openmap,x) + dist.(x,y)

            {ty, gy} = HMap.mapping(openmap,y)

            updater = fn(openmap) ->
              nparents = Dict.put(parents, y, x)
              new_gy = est_g
              fy = h.(y, goal) + new_gy
              nopenmap = openmap |> HMap.add(fy, y, new_gy)
              {nopenmap, nparents}
            end

            if gy do
              if est_g < gy do
                updater.(openmap |> HMap.delete(ty, y))
              else
                continue
              end
            else
              updater.(openmap)
            end
          end
        end

        loop(env, goal, openmap, closedset, parents)
      end
    end
  end


  @spec cons_path(Dict.t, vertex) :: [vertex]

  defp cons_path(parents, vertex), do: cons_path(parents, vertex, [])
  defp cons_path(parents, vertex, acc) do
    parent = Dict.get(parents,vertex)
    if parent do
      cons_path(parents, parent, [vertex|acc])
    else acc
    end
  end
end
