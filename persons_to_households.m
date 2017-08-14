function A = persons_to_households( M, num_of_members )
u_index = 0;
for j = 1:length(num_of_members)
    l_index = u_index + 1;
    u_index = l_index + num_of_members(j) - 1;
    A(j, :) = sum( M(l_index:u_index, :), 1 );
end