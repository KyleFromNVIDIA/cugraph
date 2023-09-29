# Copyright (c) 2023, NVIDIA CORPORATION.
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import torch

from torch_geometric.nn import CuGraphSAGEConv
from torch_geometric.utils.trim_to_layer import TrimToLayer

import torch.nn as nn
import torch.nn.functional as F

class CuGraphSAGE(nn.Module):
    def __init__(self, in_channels, hidden_channels, out_channels, num_layers):
        super().__init__()

        self.convs = torch.nn.ModuleList()
        self.convs.append(CuGraphSAGEConv(in_channels, hidden_channels, aggr='mean'))
        for _ in range(num_layers - 2):
            conv = CuGraphSAGEConv(hidden_channels, hidden_channels, aggr='mean')
            self.convs.append(conv)
        
        self.convs.append(CuGraphSAGEConv(hidden_channels, out_channels, aggr='mean'))

        self._trim = TrimToLayer()

    def forward(self, x, edge, num_sampled_nodes, num_sampled_edges):
        edge = edge.csr()
        s = edge[0].size(0) - 1
        edge = [edge[1], edge[0], s]

        x = x.cuda().to(torch.float32)
        x = x.narrow(
            dim=0,
            start=0,
            length=s
        )

        print('# sampled nodes:', num_sampled_nodes)
        print('# sampled edges:', num_sampled_edges)
        for i, conv in enumerate(self.convs):
            if i > 0:                
                edge[0] = edge[0].narrow(
                    dim=0,
                    start=0,
                    length=edge[0].size(0) - num_sampled_edges[-i],
                )
                edge[1] = edge[1].narrow(
                    dim=0,
                    start=0,
                    length=edge[1].size(0) - num_sampled_nodes[-(i+1)]
                )

                s = edge[1].size(0) - 1
                x = x.narrow(
                    dim=0,
                    start=0,
                    length=s,
                )
                edge[2] = s

            print(x.shape, edge[0].shape, edge[1].shape)
            print('i:', i)
            print(edge[0].max())
            
            print('before:', x.shape)
            x = conv(x, edge)
            print('after:', x.shape)
            x = F.relu(x)
            x = F.dropout(x, p=0.5)

        x = x.narrow(
            dim=0,
            start=0,
            length=num_sampled_nodes[0]
        )
        print(x.shape)

        # assert x.shape[0] == num_sampled_nodes[0]
        return x

