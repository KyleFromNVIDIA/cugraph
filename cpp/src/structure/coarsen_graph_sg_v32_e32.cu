/*
 * Copyright (c) 2021-2024, NVIDIA CORPORATION.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
#include "structure/coarsen_graph_impl.cuh"

namespace cugraph {

// SG instantiation

template std::tuple<
  graph_t<int32_t, int32_t, true, false>,
  std::optional<edge_property_t<graph_view_t<int32_t, int32_t, true, false>, float>>,
  std::optional<rmm::device_uvector<int32_t>>>
coarsen_graph(raft::handle_t const& handle,
              graph_view_t<int32_t, int32_t, true, false> const& graph_view,
              std::optional<edge_property_view_t<int32_t, float const*>> edge_weight_view,
              int32_t const* labels,
              bool renumber,
              bool do_expensive_check);

template std::tuple<
  graph_t<int32_t, int32_t, false, false>,
  std::optional<edge_property_t<graph_view_t<int32_t, int32_t, false, false>, float>>,
  std::optional<rmm::device_uvector<int32_t>>>
coarsen_graph(raft::handle_t const& handle,
              graph_view_t<int32_t, int32_t, false, false> const& graph_view,
              std::optional<edge_property_view_t<int32_t, float const*>> edge_weight_view,
              int32_t const* labels,
              bool renumber,
              bool do_expensive_check);

template std::tuple<
  graph_t<int32_t, int32_t, true, false>,
  std::optional<edge_property_t<graph_view_t<int32_t, int32_t, true, false>, double>>,
  std::optional<rmm::device_uvector<int32_t>>>
coarsen_graph(raft::handle_t const& handle,
              graph_view_t<int32_t, int32_t, true, false> const& graph_view,
              std::optional<edge_property_view_t<int32_t, double const*>> edge_weight_view,
              int32_t const* labels,
              bool renumber,
              bool do_expensive_check);

template std::tuple<
  graph_t<int32_t, int32_t, false, false>,
  std::optional<edge_property_t<graph_view_t<int32_t, int32_t, false, false>, double>>,
  std::optional<rmm::device_uvector<int32_t>>>
coarsen_graph(raft::handle_t const& handle,
              graph_view_t<int32_t, int32_t, false, false> const& graph_view,
              std::optional<edge_property_view_t<int32_t, double const*>> edge_weight_view,
              int32_t const* labels,
              bool renumber,
              bool do_expensive_check);

}  // namespace cugraph