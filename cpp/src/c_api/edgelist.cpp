/*
 * Copyright (c) 2022-2024, NVIDIA CORPORATION.
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

#include "c_api/edgelist.hpp"

#include <cugraph_c/algorithms.h>

extern "C" cugraph_type_erased_device_array_view_t* cugraph_edgelist_get_sources(
  cugraph_edgelist_t* edgelist)
{
  auto internal_pointer = reinterpret_cast<cugraph::c_api::cugraph_edgelist_t*>(edgelist);
  return reinterpret_cast<cugraph_type_erased_device_array_view_t*>(internal_pointer->src_->view());
}

extern "C" cugraph_type_erased_device_array_view_t* cugraph_edgelist_get_destinations(
  cugraph_edgelist_t* edgelist)
{
  auto internal_pointer = reinterpret_cast<cugraph::c_api::cugraph_edgelist_t*>(edgelist);
  return reinterpret_cast<cugraph_type_erased_device_array_view_t*>(internal_pointer->dst_->view());
}

extern "C" cugraph_type_erased_device_array_view_t* cugraph_edgelist_get_edge_weights(
  cugraph_edgelist_t* edgelist)
{
  auto internal_pointer = reinterpret_cast<cugraph::c_api::cugraph_edgelist_t*>(edgelist);
  return (internal_pointer->wgt_ == nullptr)
           ? NULL
           : reinterpret_cast<cugraph_type_erased_device_array_view_t*>(
               internal_pointer->wgt_->view());
}

extern "C" cugraph_type_erased_device_array_view_t* cugraph_edgelist_get_edge_ids(
  cugraph_edgelist_t* edgelist)
{
  auto internal_pointer = reinterpret_cast<cugraph::c_api::cugraph_edgelist_t*>(edgelist);
  return (internal_pointer->edge_ids_ == nullptr)
           ? NULL
           : reinterpret_cast<cugraph_type_erased_device_array_view_t*>(
               internal_pointer->edge_ids_->view());
}

extern "C" cugraph_type_erased_device_array_view_t* cugraph_edgelist_get_edge_type_ids(
  cugraph_edgelist_t* edgelist)
{
  auto internal_pointer = reinterpret_cast<cugraph::c_api::cugraph_edgelist_t*>(edgelist);
  return (internal_pointer->edge_type_ids_ == nullptr)
           ? NULL
           : reinterpret_cast<cugraph_type_erased_device_array_view_t*>(
               internal_pointer->edge_type_ids_->view());
}

extern "C" cugraph_type_erased_device_array_view_t* cugraph_edgelist_get_edge_offsets(
  cugraph_edgelist_t* edgelist)
{
  auto internal_pointer = reinterpret_cast<cugraph::c_api::cugraph_edgelist_t*>(edgelist);
  return reinterpret_cast<cugraph_type_erased_device_array_view_t*>(
    internal_pointer->subgraph_offsets_->view());
}

extern "C" void cugraph_edgelist_free(cugraph_edgelist_t* edgelist)
{
  auto internal_pointer = reinterpret_cast<cugraph::c_api::cugraph_edgelist_t*>(edgelist);
  delete internal_pointer->src_;
  delete internal_pointer->dst_;
  delete internal_pointer->wgt_;
  delete internal_pointer->edge_ids_;
  delete internal_pointer->edge_type_ids_;
  delete internal_pointer->subgraph_offsets_;
  delete internal_pointer;
}