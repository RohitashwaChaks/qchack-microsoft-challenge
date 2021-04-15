namespace QCHack.Task4 {
    open Microsoft.Quantum.Logical;
    open Microsoft.Quantum.Arrays;
    open Microsoft.Quantum.Canon;
    open Microsoft.Quantum.Intrinsic;
    open Microsoft.Quantum.Diagnostics;

    // Task 4 (12 points). f(x) = 1 if the graph edge coloring is triangle-free
    // 
    // Inputs:
    //      1) The number of vertices in the graph "V" (V ≤ 6).
    //      2) An array of E tuples of integers "edges", representing the edges of the graph (0 ≤ E ≤ V(V-1)/2).
    //         Each tuple gives the indices of the start and the end vertices of the edge.
    //         The vertices are indexed 0 through V - 1.
    //         The graph is undirected, so the order of the start and the end vertices in the edge doesn't matter.
    //      3) An array of E qubits "colorsRegister" that encodes the color assignments of the edges.
    //         Each color will be 0 or 1 (stored in 1 qubit).
    //         The colors of edges in this array are given in the same order as the edges in the "edges" array.
    //      4) A qubit "target" in an arbitrary state.
    //
    // Goal: Implement a marking oracle for function f(x) = 1 if
    //       the coloring of the edges of the given graph described by this colors assignment is triangle-free, i.e.,
    //       no triangle of edges connecting 3 vertices has all three edges in the same color.
    //
    // Example: a graph with 3 vertices and 3 edges [(0, 1), (1, 2), (2, 0)] has one triangle.
    // The result of applying the operation to state (|001⟩ + |110⟩ + |111⟩)/√3 ⊗ |0⟩ 
    // will be 1/√3|001⟩ ⊗ |1⟩ + 1/√3|110⟩ ⊗ |1⟩ + 1/√3|111⟩ ⊗ |0⟩.
    // The first two terms describe triangle-free colorings, 
    // and the last term describes a coloring where all edges of the triangle have the same color.
    //
    // In this task you are not allowed to use quantum gates that use more qubits than the number of edges in the graph,
    // unless there are 3 or less edges in the graph. For example, if the graph has 4 edges, you can only use 4-qubit gates or less.
    // You are guaranteed that in tests that have 4 or more edges in the graph the number of triangles in the graph 
    // will be strictly less than the number of edges.
    //
    // Hint: Make use of helper functions and helper operations, and avoid trying to fit the complete
    //       implementation into a single operation - it's not impossible but make your code less readable.
    //       GraphColoring kata has an example of implementing oracles for a similar task.
    //
    // Hint: Remember that you can examine the inputs and the intermediary results of your computations
    //       using Message function for classical values and DumpMachine for quantum states.
    //
    
    /// # Summary
    ///     Function to calculate whether all edges are of the same colour
    /// # Input
    /// ## inputs : Qubit Array of length 3, each qubit representing an edge colour
    /// 
    /// ## output : Qubit. 0 -> All edges are of same colour. 1 -> Edges of the triangle have different colour
    /// 
    internal operation IsValidTriangle ( inputs: Qubit[], output : Qubit) : Unit is Adj+Ctl {
        within{
            CNOT(inputs[0],inputs[1]);
            CNOT(inputs[0],inputs[2]);
            ApplyToEachA(X,inputs[1..2]);
        }
        apply{
            CCNOT(inputs[1],inputs[2],output);
            //X(output);
        }
    }

    /// # Summary
    ///     Function to calculate whether edges form a triangle
    /// # Input
    /// ## edges: Input Edges
    /// 
    /// # Output: 0 -> Not a Triangle ; 1 -> Triangle
    /// 
    function AreEdgesTriangle(edgeA : (Int, Int),
                                        edgeB : (Int, Int),
                                        edgeC : (Int, Int)): Bool{
        let (edge0,edge1) = edgeA;
        let (edge2,edge3) = edgeB;
        let (edge4,edge5) = edgeC;

        let vertices = [edge0,edge1,edge3,edge3,edge4,edge5];
        let un_sort_vertices = Unique(EqualI,Sorted(LessThanOrEqualI,vertices));

        let size = Length(un_sort_vertices);

        if size == 3 { 
            return true;
        }
        else{
            return false;
        }
    }


    operation Task4_TriangleFreeColoringOracle (
        V : Int, 
        edges : (Int, Int)[], 
        colorsRegister : Qubit[], 
        target : Qubit
    ) : Unit is Adj+Ctl {
        let nEdges = Length(edges);
        let count = nEdges*(nEdges-1)*(nEdges-2)/6;
        //Message($"Number of loops: {count}");        

        use conflictQubits = Qubit[count];
        within {
            for i in 0..nEdges-3{
                for j in i+1..nEdges-2{
                    for k in j+1..nEdges-1{
                        let (edge0,edge1) = edges[i];
                        let (edge2,edge3) = edges[j];
                        let (edge4,edge5) = edges[k];

                        if AreEdgesTriangle(edges[i], edges[j], edges[k]){
                            let colVec = [colorsRegister[i],colorsRegister[j],colorsRegister[k]];
                            IsValidTriangle(colVec, conflictQubits[0]);
                        }
                        DumpMachine();
                    }
                }
            }
        } 
        apply {
            //If there are no conflicts (all qubits are in 0 state), the vertex coloring is valid.
            (ControlledOnInt(0, X))(conflictQubits, target);
        }
    }
}

